#!/usr/bin/env python3
"""Inspect synthetic OpenCode request shape, optionally count native llama.cpp tokens.

No arbitrary user prompt or request-body persistence. The fake listener does
not forward requests; the OpenCode child is not an egress-restricted sandbox.
A native token-count request requires an explicitly supplied loopback-only endpoint.
"""
from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener

MARKER = "TSUMGI_SYNTHETIC_CHECK"
PROMPT = f"Reply with exactly {MARKER}. Do not read or modify files."
NATIVE_PATH = "/v1/chat/completions/input_tokens"
INPUT_TOKEN_BUDGET = 6144
AGENTS = {
    "plan": "qwen3.8-27b",  # Ephemeral override; never edit canonical Agent config.
    "tsumgi-qwen": "qwen3.8-27b",
    "tsumgi-bonsai": "bonsai2-27b",
}
MAX_BODY_BYTES = 131_072


def compact_bytes(value: object) -> int:
    return len(json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))


def require_loopback_native_url(value: str) -> str:
    parsed = urlsplit(value)
    if (
        parsed.scheme != "http"
        or parsed.hostname != "127.0.0.1"
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or parsed.path != NATIVE_PATH
        or parsed.port is None
        or parsed.port < 1024
    ):
        raise ValueError("native token endpoint must be an explicit 127.0.0.1 URL")
    canonical = f"http://127.0.0.1:{parsed.port}{NATIVE_PATH}"
    if value != canonical:
        raise ValueError("noncanonical native token endpoint")
    return value


def resolve_single_native_model(url: str) -> str:
    """Require exactly one loaded native model; keep its ID in memory only."""
    require_loopback_native_url(url)
    models_url = url.removesuffix(NATIVE_PATH) + "/v1/models"
    with build_opener(ProxyHandler({}), RejectRedirects()).open(
        Request(models_url, method="GET"), timeout=7
    ) as response:
        models = json.load(response)
    entries = models.get("data") if isinstance(models, dict) else None
    if not isinstance(entries, list) or len(entries) != 1:
        raise ValueError("native endpoint must advertise exactly one model")
    model = entries[0].get("id") if isinstance(entries[0], dict) else None
    if not isinstance(model, str) or not model:
        raise ValueError("native endpoint has no valid model ID")
    return model


def has_fixed_synthetic_prompt(messages: list[object]) -> bool:
    for message in messages:
        if not isinstance(message, dict) or message.get("role") != "user":
            continue
        # Only a fixed probe marker is checked; message contents are never recorded.
        content = message.get("content", "")
        if MARKER in json.dumps(content, ensure_ascii=False):
            return True
    return False


def validated_main_request(data: object, expected_model: str) -> tuple[dict, list, list] | None:
    if not isinstance(data, dict) or data.get("model") != expected_model:
        return None
    if type(data.get("stream")) is not bool:
        return None
    messages, tools = data.get("messages"), data.get("tools")
    if not isinstance(messages, list) or not isinstance(tools, list):
        return None
    if not tools or not has_fixed_synthetic_prompt(messages):
        return None
    return data, messages, tools


def safe_metrics(data: dict, messages: list, tools: list, body_bytes: int) -> dict:
    return {
        "main_request_bytes": body_bytes,
        "message_json_bytes": compact_bytes(messages),
        "tool_schema_json_bytes": compact_bytes(tools),
        "message_count": len(messages),
        "tool_count": len(tools),
        "max_tokens": data.get("max_tokens") if type(data.get("max_tokens")) is int else None,
        "has_reasoning_effort": "reasoning_effort" in data,
        "reasoning_effort_high": data.get("reasoning_effort") == "high",
    }


def native_token_projection(data: dict, native_model: str, *, without_tools: bool = False) -> dict:
    """Match TSUMGI's native token-relevant fields, not a byte-exact Job envelope.

    TSUMGI removes the public model alias, reinserts its own native model alias,
    and does not forward the inert reasoning_effort hint. Tool ablation is
    counterfactual and never represents an actual shipped Agent request.
    """
    keep = ("messages", "max_tokens", "temperature", "stream", "tools", "tool_choice")
    request = {key: data[key] for key in keep if key in data}
    request["model"] = native_model
    if without_tools:
        request.pop("tools", None)
        request.pop("tool_choice", None)
    return request


class RejectRedirects(HTTPRedirectHandler):
    """Do not allow native HTTP counting to escape an approved local listener."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError("native tokenizer redirects are forbidden")


def count_native_tokens(url: str, body: dict) -> int:
    require_loopback_native_url(url)
    request = Request(
        url,
        method="POST",
        headers={"Content-Type": "application/json"},
        data=json.dumps(body, ensure_ascii=False, separators=(",", ":")).encode("utf-8"),
    )
    # Never send the (in-memory) synthetic Agent request through ambient proxies.
    with build_opener(ProxyHandler({}), RejectRedirects()).open(request, timeout=12) as response:
        result = json.load(response)
    if not isinstance(result, dict):
        raise ValueError("native token result is not an object")
    count = result.get("input_tokens")
    if type(count) is not int or count < 0:
        raise ValueError("native token endpoint returned an invalid count")
    return count


def fake_sse(model: str) -> bytes:
    prefix = {"id": "chatcmpl-synthetic", "object": "chat.completion.chunk",
              "created": 1700000000, "model": model}
    frames = [
        {**prefix, "choices": [{"index": 0, "delta": {"role": "assistant", "content": MARKER},
                                "finish_reason": None}]},
        {**prefix, "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]},
    ]
    return ("".join("data: " + json.dumps(x) + "\n\n" for x in frames) +
            "data: [DONE]\n\n").encode("utf-8")


class CaptureServer(HTTPServer):

    def __init__(self, model: str):
        self.model = model
        self.auxiliary_requests = 0
        self.main_metrics: dict | None = None
        self.native_token_counts: dict | None = None
        self.native_error_type: str | None = None
        self.native_url: str | None = None
        self.native_model: str | None = None
        self.ablate_tools = False
        super().__init__(("127.0.0.1", 0), CaptureHandler)


class CaptureHandler(BaseHTTPRequestHandler):
    def log_message(self, *_args: object) -> None:
        pass  # No headers, prompts, paths, or raw bodies in logs.

    def do_POST(self) -> None:
        server = self.server
        assert isinstance(server, CaptureServer)
        try:
            n = int(self.headers.get("Content-Length", "0"))
            if n <= 0 or n > MAX_BODY_BYTES:
                raise ValueError("request body exceeds probe's bounded capacity")
            raw = self.rfile.read(n)
            data = json.loads(raw)
            raw = None  # Retain no copy in files or logs.
            main = validated_main_request(data, server.model)
            if main is None:
                server.auxiliary_requests += 1
            elif server.main_metrics is None:
                packet, messages, tools = main
                server.main_metrics = safe_metrics(packet, messages, tools, n)
                if server.native_url is not None and server.native_model is not None:
                    try:
                        count = count_native_tokens(
                            server.native_url, native_token_projection(packet, server.native_model)
                        )
                        result = {"full_input_tokens": count,
                                  "exceeds_input_budget": count > INPUT_TOKEN_BUDGET}
                        if server.ablate_tools:
                            alternative = count_native_tokens(
                                server.native_url,
                                native_token_projection(packet, server.native_model, without_tools=True),
                            )
                            result["counterfactual_without_tools"] = alternative
                            result["tool_overhead_delta"] = count - alternative
                        server.native_token_counts = result
                    except Exception as error:
                        # Only the exception class is reported. Never persist
                        # private endpoint URL, response body or request details.
                        server.native_error_type = type(error).__name__
            response = fake_sse(server.model)
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Content-Length", str(len(response)))
            self.end_headers()
            self.wfile.write(response)
        except Exception:
            response = b'{"error":"synthetic request not accepted"}'
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(response)))
            self.end_headers()
            self.wfile.write(response)


def run_probe(args: argparse.Namespace) -> dict:
    expected_model = AGENTS[args.agent]
    native_model = None
    if args.native_token_url is not None:
        require_loopback_native_url(args.native_token_url)
        if not args.acknowledge_native_target:
            raise ValueError("native measurement requires explicit target acknowledgment")
        native_model = resolve_single_native_model(args.native_token_url)
    elif args.acknowledge_native_target or args.ablate_tools:
        raise ValueError("native-only flags require --native-token-url")
    if not shutil.which("opencode"):
        raise RuntimeError("opencode executable is unavailable")

    server = CaptureServer(expected_model)
    server.native_url = args.native_token_url
    server.native_model = native_model
    server.ablate_tools = args.ablate_tools
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix="tsumgi68-synthetic-") as directory:
            root = Path(directory)
            for part in ("work", "data", "cache", "state"):
                (root / part).mkdir(mode=0o700)
            environment = os.environ.copy()
            for key in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY",
                        "http_proxy", "https_proxy", "all_proxy"):
                environment.pop(key, None)
            environment["NO_PROXY"] = "127.0.0.1,localhost"
            environment["no_proxy"] = "127.0.0.1,localhost"
            environment.update({
                "XDG_DATA_HOME": str(root / "data"),
                "XDG_CACHE_HOME": str(root / "cache"),
                "XDG_STATE_HOME": str(root / "state"),
                "OPENCODE_DISABLE_PROJECT_CONFIG": "1",
                "OPENCODE_CONFIG_CONTENT": json.dumps({
                    "provider": {"tsumgi": {"options": {
                        "baseURL": f"http://127.0.0.1:{server.server_address[1]}/v1"
                    }}}
                }),
            })
            try:
                completed = subprocess.run(
                    [
                        "opencode", "run", "--pure", "--agent", args.agent,
                        "--model", "tsumgi/" + expected_model,
                        "--format", "json", PROMPT,
                    ],
                    cwd=root / "work",
                    env=environment,
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=55,
                    check=False,
                )
                return_code: int | None = completed.returncode
            except subprocess.TimeoutExpired:
                return_code = None
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=4)

    result = {
        "agent": args.agent,
        "logical_model": expected_model,
        "fixed_synthetic_input": True,
        "fake_receiver_forwarded_requests": 0,
        "child_network_egress_restricted": False,
        "opencode_exit_code": return_code,
        "auxiliary_request_count": server.auxiliary_requests,
        "main_request": server.main_metrics,
        "native_token_measurement": server.native_token_counts,
        "native_error_type": server.native_error_type,
        "native_projection_not_byte_identical_to_gateway": True,
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--agent", choices=sorted(AGENTS), required=True)
    parser.add_argument("--native-token-url", default=None,
                        help="Optional explicitly approved loopback native token-count URL")
    parser.add_argument("--acknowledge-native-target", action="store_true",
                        help="Confirm that loopback listener is the intended authorized model backend")
    parser.add_argument("--ablate-tools", action="store_true",
                        help="Also count a counterfactual copy with Tool definitions removed")
    args = parser.parse_args()
    try:
        result = run_probe(args)
    except Exception as error:
        print(json.dumps({"status": "blocked", "error_class": type(error).__name__}))
        return 2
    print(json.dumps(result, sort_keys=True))
    return 0 if result["main_request"] is not None and result["native_error_type"] is None else 1


if __name__ == "__main__":
    sys.exit(main())
