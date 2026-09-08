from __future__ import annotations

import json
import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "packages/opencode/config"
MODELS = {
    "local-quality": ("http://10.12.2.9:1919/v1", "qwen3.6-35b-a3b-nvfp4"),
    "local-fast": ("http://10.12.2.9:8091/v1", "gemma4-12b-it-q4km-3060"),
    "local-background": ("http://10.12.2.9:8090/v1", "gemma4-12b-it-q4km-1080ti"),
}
WORKERS = {
    "local-investigator": "local-quality/qwen3.6-35b-a3b-nvfp4",
    "local-tracer": "local-fast/gemma4-12b-it-q4km-3060",
    "local-background": "local-background/gemma4-12b-it-q4km-1080ti",
}
DENIED = {"glob", "list", "lsp", "bash", "edit", "task", "question", "webfetch", "websearch", "skill", "todowrite", "external_directory", "doom_loop"}


class OpenCodeLocalWorkersTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.config = json.loads((CONFIG / "opencode.json").read_text())
        cls.manifest_text = (CONFIG / "local-workers.toml").read_text()
        cls.manifest = tomllib.loads(cls.manifest_text)

    def test_routing_mapping_limits_and_tool_call(self) -> None:
        for provider, (url, model) in MODELS.items():
            entry = self.config["provider"][provider]
            self.assertEqual(url, entry["options"]["baseURL"])
            self.assertEqual({model}, set(entry["models"]))
            self.assertEqual({"context": 32768, "output": 4096}, entry["models"][model]["limit"])
            self.assertTrue(entry["models"][model]["tool_call"])
        bindings = {
            worker["class"]: f'{worker["provider"]}/{worker["model"]}'
            for worker in self.manifest["workers"]
        }
        self.assertEqual(WORKERS, bindings)

    def test_exact_read_only_permissions_and_hidden_agents(self) -> None:
        for worker in WORKERS:
            text = (CONFIG / "agents" / f"{worker}.md").read_text()
            self.assertIn("hidden: true", text)
            self.assertIn('  "*": deny', text)
            permissions = dict(re.findall(r"^  ([a-z_]+): (allow|deny)$", text, re.MULTILINE))
            self.assertEqual({"read", "grep"}, {k for k, v in permissions.items() if v == "allow"})
            self.assertTrue(DENIED <= {k for k, v in permissions.items() if v == "deny"})

    def test_dispatch_retry_metrics_and_no_fallback(self) -> None:
        self.assertEqual(1, self.manifest["schema_version"])
        self.assertEqual("global", self.manifest["profile"])
        self.assertFalse(self.manifest["enabled_by_default"])
        self.assertEqual("explicit-manual", self.manifest["opt_in"])
        self.assertEqual("manual-or-shadow", self.manifest["dispatch"])
        self.assertEqual(1, self.manifest["max_in_flight"])
        self.assertEqual(["read", "grep"], self.manifest["required_tools"])
        self.assertEqual(1, self.manifest["retry_limit"])
        self.assertEqual("normal_successful_response_with_required_tool_call_count_0", self.manifest["retry_eligibility"])
        self.assertEqual("same_agent_same_model_only", self.manifest["retry_model_policy"])
        self.assertEqual("none", self.manifest["fallback"])
        for excluded in ("api_failure", "runtime_failure", "model_failure", "permission_failure", "schema_failure", "wrong_evidence"):
            self.assertIn(excluded, self.manifest["retry_exclusions"])
        required_metrics = {
            "local_task_total", "local_task_completed", "local_task_rejected",
            "local_task_retried", "local_tool_required_miss",
            "local_wrong_answer_detected", "local_runtime_failure",
        }
        self.assertEqual(required_metrics, set(self.manifest["metrics"]["counters"]))
        self.assertIn("attempts", self.manifest["metrics"]["metadata"])
        self.assertIn("retry_reason", self.manifest["metrics"]["metadata"])

    def test_canonical_assignments_remain_immutable(self) -> None:
        canonical = {"build": "sol", "plan": "sol", "architect": "sol", "reviewer": "terra", "investigator": "terra", "security-reviewer": "terra", "general": "luna", "explore": "luna", "verifier": "luna", "scout": "luna"}
        for agent, model in canonical.items():
            self.assertIn(f"model: openai/gpt-5.6-{model}", (CONFIG / "agents" / f"{agent}.md").read_text())
        skill = (CONFIG / "skills/local-workers/SKILL.md").read_text()
        self.assertIn("There is no\nfallback", skill)
        self.assertIn("same configured model", skill)
        self.assertIn("missing_required_tool_call", skill)

    def test_command_uses_supported_argument_expansion(self) -> None:
        command = (CONFIG / "commands/local-worker.md").read_text()
        self.assertIn("$ARGUMENTS", command)
        self.assertNotRegex(command, r"\$[0-9]")

    def test_runtime_network_policy_is_additive_and_source_restricted(self) -> None:
        policy = (CONFIG.parent / "runtime/nftables.d/opencode-local.nft").read_text()
        self.assertNotIn("flush ruleset", policy)
        self.assertIn("table inet opencode_local", policy)
        self.assertIn("ip saddr != 10.12.0.1", policy)
        self.assertIn("tcp dport { 1919, 8090, 8091 }", policy)

    def test_runtime_units_match_provider_bindings_and_nonroot_hardening(self) -> None:
        unit_dir = CONFIG.parent / "runtime/systemd"
        unit_bindings = {
            "opencode-local-quality.service": ("CUDA_VISIBLE_DEVICES=0", "--host 10.12.2.9 --port 1919", "qwen3.6-35b-a3b-nvfp4"),
            "opencode-local-fast.service": ("CUDA_VISIBLE_DEVICES=1", "--host 10.12.2.9 --port 8091", "gemma4-12b-it-q4km-3060"),
            "opencode-local-background.service": ("CUDA_VISIBLE_DEVICES=2", "--host 10.12.2.9 --port 8090", "gemma4-12b-it-q4km-1080ti"),
        }
        for filename, expected in unit_bindings.items():
            unit = (unit_dir / filename).read_text()
            for value in expected:
                self.assertIn(value, unit)
            for hardening in ("User=opencode-local", "NoNewPrivileges=yes", "ProtectSystem=strict", "CapabilityBoundingSet=", "BindReadOnlyPaths="):
                self.assertIn(hardening, unit)


if __name__ == "__main__":
    unittest.main()
