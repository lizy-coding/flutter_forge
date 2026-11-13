#!/usr/bin/env python3
"""Local development bridge: authenticated Codex CLI -> GenUI text stream.

Run separately from Forge. Does not read tokens or change CLI authentication.
Only the CLI itself uses its existing login. No repository is given to it.

Streaming: response headers and SSE keepalive comments are sent while the
CLI is still working, so long generations never look stalled to HTTP
clients. Content granularity follows `codex exec --json` events, which
complete per agent message rather than per token; CLIs without --json fall
back to the whole-response path. A disconnected client kills the CLI
process instead of letting it run to completion.
"""

import argparse
import json
import os
from pathlib import Path
import queue
import re
import secrets
import shutil
import socket
import subprocess
import tempfile
import threading
import time
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


MAX_REQUEST = 100_000
MAX_OUTPUT = 200_000
KEEPALIVE_SECONDS = 10.0
# One Codex call at a time; a second request waits for the slot instead of
# shedding instantly, so a slow previous call queues the next one. Dio
# clients give up on silence after 100s, hence the bound.
SLOT_WAIT_SECONDS = 90.0


def _proxy_reachable(url):
    # A dead system proxy (127.0.0.1:7897 on this host) would otherwise be
    # injected into the CLI environment and silently stall every call.
    try:
        parts = urllib.parse.urlsplit(url if "://" in url else f"http://{url}")
        port = parts.port or (443 if parts.scheme == "https" else 80)
        with socket.create_connection((parts.hostname, port), timeout=0.5):
            return True
    except (OSError, ValueError):
        return False


def cli_environment():
    # Native macOS apps use system proxies; CLI HTTP clients require env vars.
    # Preserve explicit user env choices; skip system proxies that no longer
    # answer. Never persist or log proxy credentials.
    env = os.environ.copy()
    for scheme, value in urllib.request.getproxies().items():
        if scheme in {"http", "https"} and value and _proxy_reachable(value):
            upper = f"{scheme.upper()}_PROXY"
            lower = f"{scheme}_proxy"
            if upper not in env and lower not in env:
                env[upper] = value
    return env


def build_prompt(messages):
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
    return "\n\n".join(prompt)


def check_model(model):
    if not isinstance(model, str) or not re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", model):
        raise ValueError("Invalid model name")
    return model


def exec_args(codex, directory, model, event_mode):
    # No shell interpolation, no project files, no reading auth.json.
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
    ]
    if event_mode:
        args.append("--json")
    if model != "codex-default":
        args[2:2] = ["--model", model]
    args += ["-C", directory, "-"]
    return args


def supports_event_mode(codex):
    """Detect `exec --json` from CLI help; no quota is consumed."""
    try:
        result = subprocess.run(
            [codex, "exec", "--help"], capture_output=True, text=True,
            timeout=15, check=False, env=cli_environment(),
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return "--json" in (result.stdout or "") + (result.stderr or "")


def _spawn(prompt, args, stdin_ok):
    process = subprocess.Popen(
        args, stdin=subprocess.PIPE if stdin_ok else subprocess.DEVNULL,
        # Diagnostics are intentionally discarded; an unread PIPE would let a
        # chatty CLI block once the pipe buffer fills.
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        env=cli_environment(),
    )
    if stdin_ok:
        # The prompt can exceed the pipe buffer; feed it from a thread so a
        # slow or dead CLI cannot deadlock the response loop.
        def feed():
            try:
                process.stdin.write(prompt)
                process.stdin.close()
            except (BrokenPipeError, OSError):
                pass
        threading.Thread(target=feed, daemon=True).start()
    return process


def _kill(process):
    if process.poll() is None:
        process.kill()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        pass
    # Pipe ownership: stdout belongs to the reader thread (event mode) or
    # the caller (legacy mode); closing it here would deadlock against a
    # concurrent read on the same file object.


class ClientGone(Exception):
    """Raised internally when the HTTP client left mid-generation."""


def generate_stream(codex, messages, model, timeout=90, cancelled=None,
                    event_mode=True):
    """Yield response content pieces; raise on failure before/while yielding.

    Validation happens before any process starts so request errors stay
    mapped to HTTP 400. `cancelled` stops the CLI when the client leaves.
    """
    prompt = build_prompt(messages)
    check_model(model)
    cancelled = cancelled or threading.Event()
    with tempfile.TemporaryDirectory(prefix="forge-genui-") as directory:
        if event_mode:
            yield from _run_event_mode(
                codex, prompt, model, timeout, directory, cancelled)
        else:
            yield from _run_legacy_mode(
                codex, prompt, model, timeout, directory, cancelled)


def _run_event_mode(codex, prompt, model, timeout, directory, cancelled):
    # Verified against codex-cli 0.163.0: agent text arrives in
    # item.completed items, transport fallbacks surface as error items, and
    # turn.completed ends the turn. Token-level deltas do not exist in exec
    # event mode, so delivery granularity is per agent message.
    args = exec_args(codex, directory, model, event_mode=True)
    process = _spawn(prompt, args, stdin_ok=True)
    lines = queue.Queue()

    def reader():
        try:
            for line in process.stdout:
                lines.put(line)
        finally:
            lines.put(None)
            # Sole owner of the pipe: close it at EOF (normal exit, kill,
            # or crash) so no descriptor leaks, never from another thread.
            try:
                process.stdout.close()
            except OSError:
                pass

    threading.Thread(target=reader, daemon=True).start()
    deadline = time.monotonic() + timeout
    produced = 0
    completed_turn = False
    try:
        while True:
            if cancelled.is_set():
                raise ClientGone()
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired(args, timeout)
            try:
                line = lines.get(timeout=min(remaining, 0.5))
            except queue.Empty:
                continue
            if line is None:
                break
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(event, dict):
                continue
            kind = event.get("type")
            if kind == "turn.completed":
                completed_turn = True
            elif kind == "turn.failed":
                raise RuntimeError("Codex turn failed")
            elif kind == "item.completed":
                item = event.get("item")
                if isinstance(item, dict) and item.get("type") == "agent_message":
                    text = item.get("text")
                    if isinstance(text, str) and text:
                        produced += len(text)
                        if produced > MAX_OUTPUT:
                            raise ValueError("Codex response too large")
                        yield text
    finally:
        _kill(process)
    code = process.wait()
    if cancelled.is_set():
        raise ClientGone()
    if code or not completed_turn or not produced:
        raise RuntimeError("Codex failed; check CLI login, quota, and model access")


def _run_legacy_mode(codex, prompt, model, timeout, directory, cancelled):
    output = Path(directory) / "response.txt"
    args = exec_args(codex, directory, model, event_mode=False)
    args.insert(len(args) - 1, "--output-last-message")
    args.insert(len(args) - 1, str(output))
    process = _spawn(prompt, args, stdin_ok=True)
    deadline = time.monotonic() + timeout
    try:
        while process.poll() is None:
            if cancelled.is_set():
                raise ClientGone()
            if time.monotonic() > deadline:
                raise subprocess.TimeoutExpired(args, timeout)
            time.sleep(0.2)
    finally:
        _kill(process)
        # No reader thread here: the unread stdout pipe is closed by its
        # single owning thread right after the process is reaped.
        try:
            process.stdout.close()
        except OSError:
            pass
    code = process.wait()
    if cancelled.is_set():
        raise ClientGone()
    if code or not output.exists():
        raise RuntimeError("Codex failed; check CLI login, quota, and model access")
    if output.stat().st_size > MAX_OUTPUT:
        raise ValueError("Codex response too large")
    text = output.read_text(encoding="utf-8")
    if text:
        yield text


class BridgeServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, token, codex, origins, event_mode=None):
        super().__init__(address, BridgeHandler)
        self.token = token
        self.codex = codex
        self.origins = origins
        if event_mode is None:
            event_mode = supports_event_mode(codex)
        self.event_mode = event_mode
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

    def _sse(self, payload):
        self.wfile.write(f"data: {payload}\n\n".encode())
        self.wfile.flush()

    def _stream_response(self, request, cancelled):
        events = queue.Queue()

        def worker():
            pieces = generate_stream(
                self.server.codex, request.get("messages"),
                request.get("model", "codex-default"),
                cancelled=cancelled, event_mode=self.server.event_mode,
            )
            try:
                for piece in pieces:
                    events.put(("content", piece))
                events.put(("done", None))
            except Exception as error:  # forwarded into the open SSE stream
                events.put(("error", error))
            finally:
                pieces.close()  # release the request temp directory now

        threading.Thread(target=worker, daemon=True).start()
        started = time.monotonic()
        while True:
            try:
                kind, payload = events.get(timeout=KEEPALIVE_SECONDS)
            except queue.Empty:
                # SSE comment: invisible to JSON parsing, resets client
                # receive timeouts, and doubles as a liveness probe that
                # turns a dead client into BrokenPipeError promptly.
                self.wfile.write(b": keepalive\n\n")
                self.wfile.flush()
                continue
            if kind == "content":
                event = {"choices": [{"delta": {"content": payload}}]}
                self._sse(json.dumps(event))
            elif kind == "done":
                break
            else:
                print(f"codex_failed type={type(payload).__name__}", flush=True)
                if isinstance(payload, ClientGone):
                    return
                self._sse(json.dumps({"error": {"message": "模型服务调用失败。"}}))
                return
        print(f"codex_completed seconds={time.monotonic() - started:.1f}", flush=True)
        self._sse("[DONE]")

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
            # Validate the request shape before opening the stream so client
            # mistakes keep the 4xx contract; CLI failures stream as errors.
            build_prompt(request.get("messages"))
            check_model(request.get("model", "codex-default"))
        except (ValueError, TypeError, json.JSONDecodeError):
            self._headers(400)
            return
        if not self.server.slot.acquire(timeout=SLOT_WAIT_SECONDS):
            self._headers(429)
            return
        cancelled = threading.Event()
        try:
            self._headers(200, "text/event-stream; charset=utf-8")
            self._stream_response(request, cancelled)
        except (BrokenPipeError, ConnectionResetError):
            # Keepalive writes probe liveness, so reaching here means the
            # client is gone; stop the CLI instead of burning quota for a
            # response nobody will read.
            cancelled.set()
        finally:
            self.server.slot.release()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--codex", default=shutil.which("codex"),
                        help="Codex executable; resolve symlinks before serving")
    parser.add_argument("--allow-origin", action="append", default=[])
    parser.add_argument("--no-event-mode", action="store_true",
                        help="Force whole-response delivery even if --json exists")
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
    event_mode = None if not args.no_event_mode else False
    with BridgeServer(("127.0.0.1", args.port), token, codex,
                      set(args.allow_origin), event_mode=event_mode) as server:
        print(f"GenUI bridge: http://127.0.0.1:{args.port}/v1/chat/completions", flush=True)
        mode = "codex exec --json events" if server.event_mode else "whole response"
        print(f"Model: codex-default; delivery: {mode}; temporary token file: {args.token_file}", flush=True)
        print("Uses existing Codex login and available usage. Ctrl-C to stop.", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            args.token_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
