from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT / "packages" / "opencode" / "config" / "agents"
ROLE_POLICY = {
    "build": ("openai/gpt-6.1-sol", "high"),
    "plan": ("openai/gpt-6.1-sol", "high"),
    "architect": ("openai/gpt-6.1-sol", "high"),
    "security-reviewer": ("openai/gpt-6.1-sol", "high"),
    "reviewer": ("openai/gpt-6-luna", "high"),
    "investigator": ("openai/gpt-6-luna", "high"),
    "general": ("openai/gpt-6-luna", "medium"),
    "explore": ("openai/gpt-6-luna", "medium"),
    "scout": ("openai/gpt-6-luna", "medium"),
    "verifier": ("openai/gpt-6-luna", "medium"),
}


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    if not match:
        raise AssertionError(f"missing frontmatter: {path}")
    return match.group(1)


class OpenCodeRoleReasoningTest(unittest.TestCase):
    def test_exact_global_role_model_and_effort(self) -> None:
        self.assertEqual(10, len(ROLE_POLICY))
        for role, (model, effort) in ROLE_POLICY.items():
            with self.subTest(role=role):
                metadata = frontmatter(AGENTS / f"{role}.md")
                assignments = re.findall(r"^(model|reasoningEffort):\s*(.*?)\s*$", metadata, re.MULTILINE)
                self.assertEqual([("model", model), ("reasoningEffort", effort)], assignments)
                self.assertNotIn(effort, {"max", "xhigh"})


if __name__ == "__main__":
    unittest.main()
