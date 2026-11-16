from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "packages" / "opencode" / "config"
AGENTS = CONFIG / "agents"
FAST = "tsumgi/qwen3.6-35b-a3b-fast"
LONG = "tsumgi/qwen3.6-35b-a3b"
ROLE_MODELS = {
    "build": FAST,
    "plan": FAST,
    "architect": FAST,
    "security-reviewer": FAST,
    "reviewer": FAST,
    "investigator": FAST,
    "general": LONG,
    "explore": LONG,
    "scout": LONG,
    "verifier": LONG,
}


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    if not match:
        raise AssertionError(f"missing frontmatter: {path}")
    return match.group(1)


class OpenCodeRoleModelTest(unittest.TestCase):
    def test_exact_global_role_model_without_reasoning_effort(self) -> None:
        self.assertEqual(10, len(ROLE_MODELS))
        for role, model in ROLE_MODELS.items():
            with self.subTest(role=role):
                metadata = frontmatter(AGENTS / f"{role}.md")
                assignments = re.findall(r"^(model|reasoningEffort):\s*(.*?)\s*$", metadata, re.MULTILINE)
                self.assertEqual([("model", model)], assignments)

    def test_no_agent_uses_openai_and_the_provider_is_disabled(self) -> None:
        config = json.loads((CONFIG / "opencode.json").read_text())
        self.assertEqual(["openai"], config["disabled_providers"])
        self.assertNotIn("openai", config["provider"])
        for path in sorted(AGENTS.glob("*.md")):
            with self.subTest(agent=path.stem):
                metadata = frontmatter(path)
                self.assertNotRegex(metadata, r"(?m)^model: openai/")
                self.assertNotRegex(metadata, r"(?m)^reasoningEffort:")
        configured = {m.split("/", 1)[1] for m in ROLE_MODELS.values()}
        self.assertLessEqual(configured, set(config["provider"]["tsumgi"]["models"]))


if __name__ == "__main__":
    unittest.main()
