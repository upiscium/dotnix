from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT / "packages" / "opencode" / "config" / "agents"
LUNA_AGENTS = {"plan", "reviewer", "investigator", "general", "explore", "verifier", "scout"}
RETAINED_MODELS = {
    "build": "openai/gpt-5.6-sol",
    "architect": "openai/gpt-5.6-sol",
    "security-reviewer": "openai/gpt-5.6-terra",
}


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    if not match:
        raise AssertionError(f"missing frontmatter: {path}")
    return match.group(1)


class OpenCodeLunaReasoningTest(unittest.TestCase):
    def test_luna_roles_use_max_reasoning(self) -> None:
        for role in sorted(LUNA_AGENTS):
            metadata = frontmatter(AGENTS / f"{role}.md")
            self.assertIn("model: openai/gpt-5.6-luna", metadata, role)
            self.assertIn("reasoningEffort: max", metadata, role)

    def test_retained_high_tier_roles_remain_explicit(self) -> None:
        for role, model in RETAINED_MODELS.items():
            metadata = frontmatter(AGENTS / f"{role}.md")
            self.assertIn(f"model: {model}", metadata, role)
            self.assertNotIn("reasoningEffort: max", metadata, role)


if __name__ == "__main__":
    unittest.main()
