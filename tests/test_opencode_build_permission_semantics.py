from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROMPT_PATH = ROOT / "packages/opencode/config/agents/build.md"


class OpenCodeBuildPermissionSemanticsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prompt = PROMPT_PATH.read_text(encoding="utf-8")

    def test_leaf_deletion_and_independent_reevaluation_are_explicit(self) -> None:
        self.assertRegex(
            self.prompt,
            r"(?is)non-interactive.*?leaf.*?local filesystem deletion.*?direct-denied.*?NEEDS_APPROVAL",
        )
        self.assertRegex(
            self.prompt,
            r"(?is)Build independently reevaluates the exact operation.*?rather than relaying",
        )

    def test_ask_is_bounded_and_does_not_grant_blanket_rm_allow(self) -> None:
        self.assertRegex(
            self.prompt,
            r"(?is)only a bounded local filesystem deletion within the configured Global build authority.*?presented to the user as `Ask`",
        )
        self.assertNotRegex(self.prompt, r"(?i)\brm\b.{0,80}\ballow(?:ed|ance)?\b")
        self.assertNotRegex(self.prompt, r"(?i)\ballow(?:ed|ance)?\b.{0,80}\brm\b")

    def test_rejection_finality_and_anti_bypass_are_explicit(self) -> None:
        self.assertRegex(
            self.prompt,
            r"(?is)exact user rejection is final.*?must not be bypassed",
        )
        for bypass in ("retry", "rephrase", "redelegation", "equivalent substitute"):
            with self.subTest(bypass=bypass):
                self.assertIn(bypass, self.prompt)

    def test_authority_boundaries_and_evidence_fields_are_required(self) -> None:
        self.assertRegex(
            self.prompt,
            r"(?is)permission mutation or auto-approval.*?out-of-authority.*?structural destructive operations.*?BLOCKED.*?denied",
        )
        evidence_fields = {
            "operation_class",
            "operation_identity",
            "scope",
            "purpose",
            "evidence",
            "least_privilege",
            "safe_alternatives",
            "configured_authority",
        }
        for field in sorted(evidence_fields):
            with self.subTest(field=field):
                self.assertIn(f"`{field}`", self.prompt)


if __name__ == "__main__":
    unittest.main()
