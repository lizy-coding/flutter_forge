#!/usr/bin/env python3
"""Bridge behaviour tests over a real loopback server with fake CLIs.

Run: python3 tool/genui_codex_bridge_test.py
No real Codex call, no network beyond 127.0.0.1, no repository writes.
"""

import http.client
import json
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import genui_codex_bridge as bridge


def write_script(directory, name, body):
    path = Path(directory) / name
    path.write_text(f"#!/bin/sh\n{body}\n")
    path.chmod(0o755)
    return str(path)


EVENT_BODY = """
cat >/dev/null
echo '{"type":"thread.started"}'
echo '{"type":"turn.started"}'
echo '{"type":"error","message":"ws fallback noise"}'
echo '{"type":"item.completed","item":{"id":"i0","type":"agent_message","text":"第一段"}}'
echo '{"type":"item.completed","item":{"id":"i1","type":"agent_message","text":"第二段"}}'
echo '{"type":"turn.completed"}'
"""

LEGACY_GUARD = """
for a in "$@"; do
  if [ "$a" = "--json" ]; then
    echo "error: unexpected argument '--json' found" >&2
    exit 2
  fi
done
prev=""
out=""
for a in "$@"; do
  if [ "$prev" = "--output-last-message" ]; then out="$a"; fi
  prev="$a"
done
"""


class BridgeFixture(unittest.TestCase):
    keepalive = None

    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(prefix="bridge-test-")
        if self.keepalive is not None:
            self._original_keepalive = bridge.KEEPALIVE_SECONDS
            bridge.KEEPALIVE_SECONDS = self.keepalive
        self.addCleanup(self.teardown_server)

    def teardown_server(self):
        if getattr(self, "server", None):
            self.server.shutdown()
            self.server.server_close()
            self.server = None
        if getattr(self, "_original_keepalive", None):
            bridge.KEEPALIVE_SECONDS = self._original_keepalive
            self._original_keepalive = None
        self.workspace.cleanup()

    def start(self, codex, event_mode):
        self.server = bridge.BridgeServer(
            ("127.0.0.1", 0), "tok", codex, set(), event_mode=event_mode)
        self.port = self.server.server_address[1]
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def post(self, payload, token="tok"):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=30)
        connection.request(
            "POST", "/v1/chat/completions", json.dumps(payload),
            {"Authorization": f"Bearer {token}",
             "Content-Type": "application/json"})
        response = connection.getresponse()
        try:
            body = response.read().decode()
        except (ConnectionResetError, ConnectionAbortedError):
            # Status was received; an immediate HTTP/1.0 close can deliver a
            # TCP reset to the client's empty-body read. Not a contract issue.
            body = ""
        status = response.status
        connection.close()
        return status, body

    @staticmethod
    def request():
        return {
            "stream": True,
            "model": "codex-default",
            "messages": [{"role": "user", "content": "问"}],
        }

    @staticmethod
    def data_events(body):
        events = []
        for line in body.splitlines():
            if line.startswith("data:"):
                events.append(line[5:].strip())
        return events


class EventModeTest(BridgeFixture):
    keepalive = 0.5

    def test_streams_pieces_in_order_then_done(self):
        codex = write_script(self.workspace.name, "codex", EVENT_BODY)
        self.start(codex, event_mode=True)
        status, body = self.post(self.request())
        self.assertEqual(status, 200)
        events = self.data_events(body)
        self.assertEqual(events[-1], "[DONE]")
        contents = [json.loads(e)["choices"][0]["delta"]["content"]
                    for e in events[:-1]]
        self.assertEqual(contents, ["第一段", "第二段"])

    def test_malformed_lines_are_ignored(self):
        codex = write_script(self.workspace.name, "codex", """
cat >/dev/null
echo 'not-json-at-all'
""" + EVENT_BODY)
        self.start(codex, event_mode=True)
        _, body = self.post(self.request())
        events = self.data_events(body)
        self.assertEqual(events[-1], "[DONE]")
        self.assertEqual(len(events), 3)

    def test_turn_failed_streams_error_without_done(self):
        codex = write_script(self.workspace.name, "codex", """
cat >/dev/null
echo '{"type":"turn.started"}'
echo '{"type":"turn.failed","error":{"message":"quota"}}'
exit 1
""")
        self.start(codex, event_mode=True)
        _, body = self.post(self.request())
        events = self.data_events(body)
        self.assertEqual(len(events), 1)
        self.assertIn("error", json.loads(events[0]))

    def test_silent_success_is_rejected(self):
        codex = write_script(self.workspace.name, "codex", """
cat >/dev/null
echo '{"type":"turn.completed"}'
""")
        self.start(codex, event_mode=True)
        _, body = self.post(self.request())
        events = self.data_events(body)
        self.assertEqual(len(events), 1)
        self.assertIn("error", json.loads(events[0]))

    def test_oversized_response_is_rejected(self):
        original = bridge.MAX_OUTPUT
        bridge.MAX_OUTPUT = 64
        try:
            codex = write_script(self.workspace.name, "codex", """
cat >/dev/null
echo '{"type":"item.completed","item":{"id":"i0","type":"agent_message","text":"$(head -c 200 /dev/zero | tr '\\\\0' 'a')"}}'
echo '{"type":"turn.completed"}'
""")
            self.start(codex, event_mode=True)
            _, body = self.post(self.request())
            self.assertIn("error", body)
            self.assertNotIn("[DONE]", body)
        finally:
            bridge.MAX_OUTPUT = original

    def test_keepalive_comments_precede_content(self):
        codex = write_script(self.workspace.name, "codex", """
sleep 2
""" + EVENT_BODY)
        self.start(codex, event_mode=True)
        _, body = self.post(self.request())
        self.assertIn(": keepalive", body)
        self.assertIn("[DONE]", body)


class LegacyModeTest(BridgeFixture):
    def test_whole_response_fallback(self):
        codex = write_script(self.workspace.name, "codex", LEGACY_GUARD + """
printf '整段响应' > "$out"
""")
        self.start(codex, event_mode=False)
        status, body = self.post(self.request())
        self.assertEqual(status, 200)
        events = self.data_events(body)
        self.assertEqual(events[-1], "[DONE]")
        contents = [json.loads(e)["choices"][0]["delta"]["content"]
                    for e in events[:-1]]
        self.assertEqual(contents, ["整段响应"])

    def test_help_detection(self):
        with_help = write_script(self.workspace.name, "with-json", """
if [ "$2" = "--help" ]; then echo '  --json   Print events as JSONL'; exit 0; fi
exit 3
""")
        without_help = write_script(self.workspace.name, "without-json", """
if [ "$2" = "--help" ]; then echo 'usage: codex exec'; exit 0; fi
exit 3
""")
        self.assertTrue(bridge.supports_event_mode(with_help))
        self.assertFalse(bridge.supports_event_mode(without_help))
        self.assertFalse(bridge.supports_event_mode(
            str(self.workspace.name) + "/missing"))


class RequestContractTest(BridgeFixture):
    def setUp(self):
        super().setUp()
        codex = write_script(self.workspace.name, "codex", EVENT_BODY)
        self.start(codex, event_mode=True)

    def test_non_streaming_request_is_rejected(self):
        payload = self.request()
        payload["stream"] = False
        status, _ = self.post(payload)
        self.assertEqual(status, 400)

    def test_bad_role_is_rejected(self):
        payload = self.request()
        payload["messages"] = [{"role": "assistant", "content": "x"}]
        status, _ = self.post(payload)
        self.assertEqual(status, 400)

    def test_bad_model_is_rejected(self):
        payload = self.request()
        payload["model"] = "bad model!"
        status, _ = self.post(payload)
        self.assertEqual(status, 400)

    def test_missing_token_is_unauthorized(self):
        status, _ = self.post(self.request(), token="wrong")
        self.assertEqual(status, 401)


class DisconnectTest(BridgeFixture):
    keepalive = 0.3

    def test_closed_client_kills_the_cli(self):
        pid_file = Path(self.workspace.name) / "pid"
        codex = write_script(self.workspace.name, "codex", f"""
echo $$ > {pid_file}
sleep 60
""")
        self.start(codex, event_mode=True)
        sock = socket.create_connection(("127.0.0.1", self.port), timeout=10)
        body = json.dumps(self.request()).encode()
        sock.sendall(
            b"POST /v1/chat/completions HTTP/1.0\r\n"
            b"Authorization: Bearer tok\r\n"
            b"Content-Type: application/json\r\n"
            + f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
        # Read the SSE headers, then hang up while the fake CLI "runs".
        deadline = time.monotonic() + 5
        header = b""
        while b"\r\n\r\n" not in header and time.monotonic() < deadline:
            header += sock.recv(4096)
        self.assertIn(b"200", header.split(b"\r\n")[0])
        sock.close()
        deadline = time.monotonic() + 10
        killed = False
        while time.monotonic() < deadline:
            time.sleep(0.2)
            if not pid_file.exists():
                continue
            pid = pid_file.read_text().strip()
            probe = subprocess.run(
                ["kill", "-0", pid], capture_output=True, check=False)
            if probe.returncode != 0:
                killed = True
                break
        self.assertTrue(killed, "fake CLI should be killed after disconnect")
        # Wait for the handler to release the bridge slot, then give the
        # daemon worker its sub-0.5s poll interval to unwind the generator
        # and delete its request temp directory; otherwise interpreter
        # shutdown collects it first and emits a ResourceWarning.
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if self.server.slot.acquire(blocking=False):
                self.server.slot.release()
                break
            time.sleep(0.1)
        time.sleep(0.75)


class ProxyLivenessTest(unittest.TestCase):
    def test_live_proxy_is_accepted(self):
        server = bridge.ThreadingHTTPServer(("127.0.0.1", 0), bridge.BridgeHandler)
        try:
            threading.Thread(target=server.serve_forever, daemon=True).start()
            self.assertTrue(bridge._proxy_reachable(
                f"http://127.0.0.1:{server.server_address[1]}"))
        finally:
            server.server_close()

    def test_dead_proxy_is_rejected(self):
        self.assertFalse(bridge._proxy_reachable("http://127.0.0.1:1"))
        self.assertFalse(bridge._proxy_reachable("not a url"))

class ProxyEnvironmentTest(unittest.TestCase):
    def test_system_proxy_injected_only_when_reachable(self):
        with patch.dict(bridge.os.environ, {}, clear=True), patch.object(
            bridge.urllib.request, "getproxies",
            return_value={"https": "http://127.0.0.1:7897"},
        ), patch.object(bridge, "_proxy_reachable", return_value=True):
            child = bridge.cli_environment()
            self.assertEqual(child["HTTPS_PROXY"], "http://127.0.0.1:7897")
            self.assertNotIn("HTTPS_PROXY", bridge.os.environ)
        with patch.dict(bridge.os.environ, {}, clear=True), patch.object(
            bridge.urllib.request, "getproxies",
            return_value={"https": "http://127.0.0.1:7897"},
        ), patch.object(bridge, "_proxy_reachable", return_value=False):
            self.assertNotIn("HTTPS_PROXY", bridge.cli_environment())

    def test_explicit_user_env_wins_over_system_proxy(self):
        with patch.dict(
            bridge.os.environ, {"https_proxy": "http://explicit:8080"}, clear=True,
        ), patch.object(
            bridge.urllib.request, "getproxies",
            return_value={"https": "http://system:7897"},
        ), patch.object(bridge, "_proxy_reachable", return_value=True):
            env = bridge.cli_environment()
            self.assertNotIn("HTTPS_PROXY", env)
            self.assertEqual(env["https_proxy"], "http://explicit:8080")


if __name__ == "__main__":
    unittest.main()
