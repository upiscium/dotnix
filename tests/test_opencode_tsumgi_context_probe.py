"""Unit tests for the synthetic-only TSUMGI context probe (#68)."""
from __future__ import annotations

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
from pathlib import Path
import subprocess
import threading
import unittest
from unittest import mock
from urllib.request import ProxyHandler, Request, build_opener


PATH = Path(__file__).resolve().parents[1] / "tools/tsumgi-context-probe.py"
SPEC = importlib.util.spec_from_file_location("tsumgi_context_probe", PATH)
assert SPEC and SPEC.loader
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


def send_local(port: int, data: dict) -> bytes:
    body = json.dumps(data).encode()
    request = Request(
        f"http://127.0.0.1:{port}/v1/chat/completions",
        data=body, headers={"Content-Type": "application/json"},
    )
    with build_opener(ProxyHandler({})).open(request, timeout=4) as response:
        return response.read()


class TokenBackendHandler(BaseHTTPRequestHandler):
    seen = []

    def log_message(self, *_args):
        pass

    def do_GET(self):
        assert self.path == "/v1/models"
        payload = json.dumps({"data": [{"id": "pinned-native"}]}).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_POST(self):
        assert self.path == probe.NATIVE_PATH
        length = int(self.headers["Content-Length"])
        data = json.loads(self.rfile.read(length))
        self.seen.append(data)
        result = {"input_tokens": 6300 if data.get("tools") else 5300}
        payload = json.dumps(result).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


class RedirectNativeHandler(BaseHTTPRequestHandler):
    destination = "http://not-loopback.invalid/unsafe"

    def log_message(self, *_args):
        pass

    def do_GET(self):
        self.send_response(302)
        self.send_header("Location", self.destination)
        self.end_headers()

    def do_POST(self):
        self.send_response(302)
        self.send_header("Location", self.destination)
        self.end_headers()


class RedirectSentinelHandler(BaseHTTPRequestHandler):
    hits = 0

    def log_message(self, *_args):
        pass

    def do_GET(self):
        type(self).hits += 1
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        type(self).hits += 1
        self.send_response(200)
        self.end_headers()


class ProbeTests(unittest.TestCase):
    @staticmethod
    def sample(*, tools: int = 3) -> dict:
        return {
            "model": probe.AGENTS["tsumgi-qwen"],
            "messages": [
                {"role": "system", "content": "bounded synthetic fixture"},
                {"role": "user", "content": probe.PROMPT},
            ],
            "tools": [
                {"type": "function", "function": {
                    "name": f"read_{i}", "description": "synthetic test definition",
                    "parameters": {"type": "object", "properties": {}},
                }}
                for i in range(tools)
            ],
            "max_tokens": 2048,
            "stream": True,
            "stream_options": {"include_usage": True},
            "reasoning_effort": "high",
            "tool_choice": "auto",
        }

    def test_native_endpoints_only_literal_loopback(self):
        good = "http://127.0.0.1:18882/v1/chat/completions/input_tokens"
        self.assertEqual(good, probe.require_loopback_native_url(good))
        for bad in (
            "http://localhost:18882/v1/chat/completions/input_tokens",
            "http://127.0.0.2:18882/v1/chat/completions/input_tokens",
            "http://127.0.0.1:18882/v1/chat/completions",
            "https://127.0.0.1:18882/v1/chat/completions/input_tokens",
            "http://someone@127.0.0.1:18882/v1/chat/completions/input_tokens",
            good + "?secret=leak", good + "#fragment",
            "http://127.0.0.1/v1/chat/completions/input_tokens",
            "http://127.0.0.1:80/v1/chat/completions/input_tokens",
            "http://127.0.0.1:18882/v1/chat/completions/input_tokens/",
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                probe.require_loopback_native_url(bad)

    def test_only_known_main_synthetic_request_is_selected(self):
        sample = self.sample()
        self.assertIsNotNone(probe.validated_main_request(sample, sample["model"]))
        for bad in (
            {**sample, "tools": []},
            {**sample, "messages": [{"role": "user", "content": "real prompt"}]},
            {**sample, "model": "unexpected model"},
            {**sample, "stream": "true"},
        ):
            self.assertIsNone(probe.validated_main_request(bad, sample["model"]))

    def test_metrics_do_not_include_prompt_or_tool_text(self):
        sample = self.sample()
        shape = probe.safe_metrics(sample, sample["messages"], sample["tools"], 7123)
        serial = json.dumps(shape)
        self.assertNotIn(probe.MARKER, serial)
        self.assertNotIn("synthetic test definition", serial)
        self.assertNotIn("read_0", serial)
        self.assertEqual(shape["tool_count"], 3)
        self.assertEqual(shape["main_request_bytes"], 7123)
        self.assertEqual(shape["reasoning_effort_high"], True)

    def test_native_projection_removes_inert_and_public_fields(self):
        data = self.sample()
        native = probe.native_token_projection(data, "native-pinned")
        self.assertEqual(native["model"], "native-pinned")
        self.assertEqual(native["messages"], data["messages"])
        self.assertEqual(native["tools"], data["tools"])
        self.assertNotIn("reasoning_effort", native)
        self.assertNotIn("stream_options", native)
        without = probe.native_token_projection(data, "native-pinned", without_tools=True)
        self.assertNotIn("tools", without)
        self.assertNotIn("tool_choice", without)
        self.assertEqual(without["messages"], data["messages"])

    def test_fake_native_token_count_and_ablation(self):
        TokenBackendHandler.seen = []
        native = ThreadingHTTPServer(("127.0.0.1", 0), TokenBackendHandler)
        thread = threading.Thread(target=native.serve_forever, daemon=True)
        thread.start()
        try:
            url = f"http://127.0.0.1:{native.server_address[1]}{probe.NATIVE_PATH}"
            self.assertEqual("pinned-native", probe.resolve_single_native_model(url))
            sample = self.sample()
            self.assertEqual(6300, probe.count_native_tokens(
                url, probe.native_token_projection(sample, "native")
            ))
            self.assertEqual(5300, probe.count_native_tokens(
                url, probe.native_token_projection(sample, "native", without_tools=True)
            ))
            self.assertEqual(len(TokenBackendHandler.seen), 2)
        finally:
            native.shutdown()
            native.server_close()
            thread.join(timeout=3)

    def test_native_redirect_is_rejected_before_leaving_loopback(self):
        RedirectSentinelHandler.hits = 0
        sentinel = ThreadingHTTPServer(("127.0.0.1", 0), RedirectSentinelHandler)
        sentinel_thread = threading.Thread(target=sentinel.serve_forever, daemon=True)
        sentinel_thread.start()
        RedirectNativeHandler.destination = (
            f"http://127.0.0.1:{sentinel.server_address[1]}/unsafe"
        )
        server = ThreadingHTTPServer(("127.0.0.1", 0), RedirectNativeHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            url = f"http://127.0.0.1:{server.server_address[1]}{probe.NATIVE_PATH}"
            with self.assertRaises(ValueError):
                probe.resolve_single_native_model(url)
            with self.assertRaises(ValueError):
                probe.count_native_tokens(
                    url, probe.native_token_projection(self.sample(), "native")
                )
            self.assertEqual(RedirectSentinelHandler.hits, 0)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)
            sentinel.shutdown()
            sentinel.server_close()
            sentinel_thread.join(timeout=3)

    def test_capture_server_returns_fake_sse_without_logging_raw(self):
        server = probe.CaptureServer(probe.AGENTS["tsumgi-qwen"])
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            packet = self.sample()
            aux = {**packet, "tools": []}
            self.assertIn(b"data: [DONE]", send_local(server.server_address[1], aux))
            self.assertIn(b"data: [DONE]", send_local(server.server_address[1], packet))
            self.assertEqual(server.auxiliary_requests, 1)
            self.assertEqual(server.main_metrics["tool_count"], 3)
            self.assertIsNone(server.native_token_counts)
            self.assertNotIn(probe.MARKER, json.dumps(server.main_metrics))
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)

    def test_capture_server_native_count_and_tool_ablation(self):
        TokenBackendHandler.seen = []
        native = ThreadingHTTPServer(("127.0.0.1", 0), TokenBackendHandler)
        backend_thread = threading.Thread(target=native.serve_forever, daemon=True)
        backend_thread.start()
        capture = probe.CaptureServer(probe.AGENTS["tsumgi-qwen"])
        capture.native_url = (
            f"http://127.0.0.1:{native.server_address[1]}{probe.NATIVE_PATH}"
        )
        capture.native_model = "pinned-native"
        capture.ablate_tools = True
        thread = threading.Thread(target=capture.serve_forever, daemon=True)
        thread.start()
        try:
            packet = self.sample()
            send_local(capture.server_address[1], {**packet, "tools": []})
            send_local(capture.server_address[1], packet)
            self.assertIsNone(capture.native_error_type)
            counts = capture.native_token_counts
            self.assertIsNotNone(counts)
            self.assertEqual(counts["full_input_tokens"], 6300)
            self.assertEqual(counts["counterfactual_without_tools"], 5300)
            self.assertEqual(counts["tool_overhead_delta"], 1000)
            self.assertTrue(counts["exceeds_input_budget"])
            self.assertEqual(len(TokenBackendHandler.seen), 2)
            self.assertTrue(all(
                x["model"] == "pinned-native" for x in TokenBackendHandler.seen
            ))
            self.assertNotIn("pinned-native", json.dumps(capture.main_metrics))
        finally:
            capture.shutdown()
            capture.server_close()
            thread.join(timeout=3)
            native.shutdown()
            native.server_close()
            backend_thread.join(timeout=3)

    def test_native_mode_must_acknowledge_target(self):
        args = type("Args", (), {
            "agent": "tsumgi-qwen",
            "native_token_url": (
                "http://127.0.0.1:18882/v1/chat/completions/input_tokens"
            ),
            "acknowledge_native_target": False,
            "ablate_tools": False,
        })()
        with self.assertRaises(ValueError):
            probe.run_probe(args)

    def test_real_workflow_uses_temporary_dirs_and_no_native(self):
        temporary_workdirs = []

        def fake_subprocess(argv, *, cwd, env, stdin, stdout, stderr, timeout, check):
            self.assertEqual(argv[0:3], ["opencode", "run", "--pure"])
            self.assertEqual(stdin, subprocess.DEVNULL)
            self.assertEqual(stdout, subprocess.DEVNULL)
            self.assertEqual(stderr, subprocess.DEVNULL)
            self.assertEqual(env["OPENCODE_DISABLE_PROJECT_CONFIG"], "1")
            self.assertEqual(env["NO_PROXY"], "127.0.0.1,localhost")
            self.assertNotIn("HTTP_PROXY", env)
            self.assertNotIn("HTTPS_PROXY", env)
            configuration = json.loads(env["OPENCODE_CONFIG_CONTENT"])
            endpoint = configuration["provider"]["tsumgi"]["options"]["baseURL"]
            self.assertTrue(endpoint.startswith("http://127.0.0.1:"))
            port = int(endpoint.split(":")[2].split("/")[0])
            self.assertTrue(Path(cwd).is_dir())
            temporary_workdirs.append(Path(cwd))
            data = self.sample()
            self.assertIn(b"data: [DONE]", send_local(port, {**data, "tools": []}))
            self.assertIn(b"data: [DONE]", send_local(port, data))
            return subprocess.CompletedProcess(argv, 0)

        args = type("Args", (), {
            "agent": "tsumgi-qwen", "native_token_url": None,
            "acknowledge_native_target": False,
            "ablate_tools": False,
        })()
        with mock.patch.object(probe.shutil, "which", return_value="/bin/opencode"), \
             mock.patch.object(probe.subprocess, "run", side_effect=fake_subprocess):
            outcome = probe.run_probe(args)
        self.assertEqual(outcome["fake_receiver_forwarded_requests"], 0)
        self.assertFalse(outcome["child_network_egress_restricted"])
        self.assertEqual(outcome["main_request"]["tool_count"], 3)
        self.assertEqual(outcome["auxiliary_request_count"], 1)
        self.assertIsNone(outcome["native_token_measurement"])
        self.assertFalse(temporary_workdirs[0].exists())
        self.assertNotIn(probe.MARKER, json.dumps(outcome))


if __name__ == "__main__":
    unittest.main()
