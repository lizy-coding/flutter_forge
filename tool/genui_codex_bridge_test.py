import json
from pathlib import Path
import subprocess
import io
import threading
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import genui_codex_bridge as bridge


class BridgeTests(unittest.TestCase):
    def test_system_proxy_is_only_in_child_environment(self):
        with patch.dict(bridge.os.environ, {}, clear=True), patch.object(bridge.urllib.request, "getproxies", return_value={"https": "http://127.0.0.1:7897"}):
            child = bridge.cli_environment()
            self.assertEqual(child["HTTPS_PROXY"], "http://127.0.0.1:7897")
            self.assertNotIn("HTTPS_PROXY", bridge.os.environ)
        with patch.dict(bridge.os.environ, {"https_proxy": "http://explicit:8080"}, clear=True), patch.object(bridge.urllib.request, "getproxies", return_value={"https": "http://system:7897"}):
            self.assertNotIn("HTTPS_PROXY", bridge.cli_environment())
            self.assertEqual(bridge.cli_environment()["https_proxy"], "http://explicit:8080")

    def handler(self, token="Bearer temporary", origin=None):
        handler = object.__new__(bridge.BridgeHandler)
        handler.server = SimpleNamespace(token="temporary", codex="codex", origins={"http://localhost:7357"}, slot=threading.Lock())
        handler.connection = SimpleNamespace(settimeout=lambda _: None)
        handler.path = "/v1/chat/completions"
        payload = json.dumps({"model": "codex-default", "stream": True, "messages": [{"role": "user", "content": "public question"}]}).encode()
        handler.headers = {"Authorization": token, "Content-Length": str(len(payload))}
        if origin:
            handler.headers["Origin"] = origin
        handler.rfile = io.BytesIO(payload)
        handler.wfile = io.BytesIO()
        handler._headers = lambda status, *_: setattr(handler, "status", status)
        return handler

    def test_auth_and_origin_reject_without_invoking_codex(self):
        with patch.object(bridge, "generate") as generate:
            for handler, status in [
                (self.handler(token=""), 401),
                (self.handler(origin="https://unrelated.invalid"), 403),
            ]:
                handler.do_POST()
                self.assertEqual(handler.status, status)
            generate.assert_not_called()

    def test_authenticated_completion_delivered_with_done_marker(self):
        handler = self.handler()
        with patch.object(bridge, "generate", return_value="约束"):
            handler.do_POST()
        self.assertEqual(handler.status, 200)
        self.assertIn(b"data: [DONE]", handler.wfile.getvalue())
        self.assertNotIn(b"temporary", handler.wfile.getvalue())

    def test_codex_receives_only_text_in_empty_readonly_workspace(self):
        captured = {}

        def run(args, **kwargs):
            captured.update(args=args, kwargs=kwargs)
            output = Path(args[args.index("--output-last-message") + 1])
            output.write_text('{"version":"v0.9"}', encoding="utf-8")
            self.assertEqual(list(Path(kwargs["cwd"]).iterdir()), [output])
            return subprocess.CompletedProcess(args, 0)

        with patch.object(bridge.subprocess, "run", side_effect=run):
            result = bridge.generate("/usr/local/bin/codex", [
                {"role": "system", "content": "catalog"},
                {"role": "user", "content": "public constraint question"},
            ], "codex-default")
        self.assertEqual(json.loads(result)["version"], "v0.9")
        args = captured["args"]
        self.assertIn("--ignore-user-config", args)
        self.assertIn('instructions=""', args)
        self.assertIn("project_doc_max_bytes=0", args)
        self.assertIn("skills.include_instructions=false", args)
        self.assertIn("memories.use_memories=false", args)
        self.assertIn("features.apps=false", args)
        self.assertIn("mcp_servers={}", args)
        self.assertIn("--ephemeral", args)
        self.assertIn("read-only", args)
        self.assertIn("shell_tool", args)
        self.assertNotIn("--model", args)
        self.assertFalse(captured["kwargs"].get("shell", False))
        self.assertIn("public constraint question", captured["kwargs"]["input"])

    def test_cli_failure_is_not_released_as_generation(self):
        with patch.object(bridge.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            with self.assertRaises(RuntimeError):
                bridge.generate("codex", [{"role": "user", "content": "question"}], "codex-default")

    def test_nontext_messages_and_invalid_model_rejected_before_process(self):
        with patch.object(bridge.subprocess, "run") as run:
            for messages, model in [
                ([], "test"),
                ([{"role": "user", "content": {"file": "secret"}}], "test"),
                ([{"role": "tool", "content": "bad"}], "test"),
                ([{"role": "user", "content": "ok"}], "model; command"),
            ]:
                with self.assertRaises(ValueError):
                    bridge.generate("codex", messages, model)
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
