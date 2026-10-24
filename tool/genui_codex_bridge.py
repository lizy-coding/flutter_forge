#!/usr/bin/env python3
"""Local development bridge: authenticated Codex CLI -> GenUI text stream.

Run separately from Forge. Does not read tokens or change CLI authentication.
Only the CLI itself uses its existing login. No repository is given to it.
"""

import argparse
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import tempfile
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


MAX_REQUEST = 100_000
MAX_OUTPUT = 200_000


def cli_environment():
    # Native macOS apps use system proxies; CLI HTTP clients require env vars.
    # Preserve explicit user env choices. Never persist or log proxy credentials.
    env = os.environ.copy()
    for scheme, value in urllib.request.getproxies().items():
        if scheme in {"http", "https"} and value:
            upper = f"{scheme.upper()}_PROXY"
            lower = f"{scheme}_proxy"
            if upper not in env and lower not in env:
                env[upper] = value
    return env


def generate(codex, messages, model, timeout=90):
    if not isinstance(messages, list) or not 1 <= len(messages) <= 4:
        raise ValueError("Expected 1–4 text messages")
    prompt = []
    for message in messages:
        if not isinstance(message, dict) or message.get("role") not in {"system", "user"}:
            raise ValueError("Only system/user text is accepted")
        content = message.get("content")
        if not isinstance(content, str):
            raise ValueError("Only text content is accepted")
        prompt.append(f"{message['role']}:\n{content}")
    if not isinstance(model, str) or not re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", model):
        raise ValueError("Invalid model name")
    with tempfile.TemporaryDirectory(prefix="forge-genui-") as directory:
        output = Path(directory) / "response.txt"
        args = [
            codex, "exec", "--ignore-user-config",
            "-c", 'model_reasoning_effort="low"', "-c", 'instructions=""', "-c", "project_doc_max_bytes=0",
            "-c", "skills.include_instructions=false",
            "-c", "memories.use_memories=false",
            "-c", "memories.generate_memories=false",
            "-c", "features.apps=false", "-c", "mcp_servers={}",
            "--ephemeral", "--skip-git-repo-check", "--sandbox", "read-only",
            "--disable", "shell_tool", "--disable", "multi_agent",
            "--disable", "multi_agent_v2", "--color", "never",
            "-C", directory, "--output-last-message", str(output), "-",
        ]
        if model != "codex-default":
            args[2:2] = ["--model", model]
        # No shell interpolation, no project files, no reading auth.json.
        # Capture diagnostics in a temporary file, never return credentials or
        # CLI logs to HTTP callers. Wait for CLI success before releasing UI.
        with tempfile.TemporaryFile() as diagnostics:
            result = subprocess.run(
                args, input="\n\n".join(prompt), text=True,
                stdout=diagnostics, stderr=diagnostics, timeout=timeout,
                check=False, cwd=directory, env=cli_environment(),
            )
        if result.returncode or not output.exists():
            raise RuntimeError("Codex failed; check CLI login, quota, and model access")
        if output.stat().st_size > MAX_OUTPUT:
            raise ValueError("Codex response too large")
        return output.read_text(encoding="utf-8")


class BridgeServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, token, codex, origins):
        super().__init__(address, BridgeHandler)
        self.token = token
        self.codex = codex
        self.origins = origins
        self.slot = threading.Lock()


class BridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass  # Requests include user prompts; keep the bridge log metadata-only.

    def _headers(self, status, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        origin = self.headers.get("Origin")
        if origin in self.server.origins:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.end_headers()

    def do_OPTIONS(self):
        self._headers(204 if self.headers.get("Origin") in self.server.origins else 403)

    def do_POST(self):
        self.connection.settimeout(15)
        if self.path != "/v1/chat/completions":
            self._headers(404)
            return
        origin = self.headers.get("Origin")
        if origin and origin not in self.server.origins:
            self._headers(403)
            return
        authorization = self.headers.get("Authorization", "")
        if not secrets.compare_digest(authorization, f"Bearer {self.server.token}"):
            self._headers(401)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= MAX_REQUEST:
                raise ValueError("Invalid request size")
            request = json.loads(self.rfile.read(length))
            if not isinstance(request, dict) or request.get("stream") is not True:
                raise ValueError("Expected a streaming request object")
            if not self.server.slot.acquire(blocking=False):
                self._headers(429)
                return
            try:
                started = time.monotonic()
                response = generate(
                    self.server.codex, request.get("messages"),
                    request.get("model", "codex-default"),
                )
                print(f"codex_completed seconds={time.monotonic() - started:.1f}", flush=True)
            finally:
                self.server.slot.release()
            self._headers(200, "text/event-stream; charset=utf-8")
            # Codex exec yields a final validated completion. HTTP chunks here
            # are delivery chunks, not model-token streaming or token timing.
            for index in range(0, len(response), 1024):
                event = {"choices": [{"delta": {"content": response[index:index + 1024]}}]}
                self.wfile.write(f"data: {json.dumps(event)}\n\n".encode())
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            return
        except (ValueError, TypeError, json.JSONDecodeError):
            self._headers(400)
        except (RuntimeError, subprocess.TimeoutExpired, OSError) as error:
            print(f"codex_failed type={type(error).__name__}", flush=True)
            if isinstance(error, FileNotFoundError):
                print(f"missing_path={error.filename}", flush=True)
            self._headers(502)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--codex", default=shutil.which("codex"),
                        help="Codex executable; resolve symlinks before serving")
    parser.add_argument("--allow-origin", action="append", default=[])
    parser.add_argument("--token-file", type=Path, required=True,
                        help="Create a new local token file (0600); never overwrite")
    args = parser.parse_args()
    if not args.codex:
        parser.error("Install Codex CLI and run codex login first")
    try:
        codex = str(Path(args.codex).expanduser().resolve(strict=True))
    except OSError:
        parser.error("Codex executable does not exist")
    if not os.access(codex, os.X_OK):
        parser.error("Codex path is not executable")
    token = secrets.token_urlsafe(32)
    descriptor = os.open(args.token_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w") as file:
        file.write(token)
    with BridgeServer(("127.0.0.1", args.port), token, codex, set(args.allow_origin)) as server:
        print(f"GenUI bridge: http://127.0.0.1:{args.port}/v1/chat/completions", flush=True)
        print(f"Model: codex-default; temporary token file: {args.token_file}", flush=True)
        print("Uses existing Codex login and available usage. Ctrl-C to stop.", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            args.token_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
