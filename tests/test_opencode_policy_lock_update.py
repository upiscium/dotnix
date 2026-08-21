from __future__ import annotations

import copy
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools" / "check_opencode_policy_lock_update.py"
SPEC = importlib.util.spec_from_file_location("check_opencode_policy_lock_update", MODULE_PATH)
assert SPEC and SPEC.loader
checker = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = checker
SPEC.loader.exec_module(checker)


class OpenCodePolicyLockUpdateTest(unittest.TestCase):
    OLD_REV = "e4ff446514c303fe275ba9eb3a4ab498caea7ac0"
    NEW_REV = "103b47b67a7e650835ac277ed192dbc92d1639c4"

    def lock(self, *, unrelated: bool = False) -> dict:
        root_inputs = {
            "nixpkgs": "nixpkgs",
            "opencodePolicy": "opencodePolicy",
        }
        nodes = {
            "root": {"inputs": root_inputs},
            "nixpkgs": {"locked": {"rev": "1" * 40}},
            "opencodePolicy": {
                "inputs": {"nixpkgs": ["nixpkgs"]},
                "locked": {
                    "owner": "upiscium",
                    "repo": "OpenCodePolicy",
                    "type": "github",
                    "rev": self.OLD_REV,
                    "narHash": "old",
                    "lastModified": 1,
                },
            },
        }
        if unrelated:
            root_inputs["other"] = "other"
            nodes["other"] = {"locked": {"rev": "2" * 40}}
        return {"nodes": nodes, "root": "root", "version": 7}

    def update_policy(self, lock: dict) -> dict:
        updated = copy.deepcopy(lock)
        updated["nodes"]["opencodePolicy"]["locked"].update(
            rev=self.NEW_REV,
            narHash="new",
            lastModified=2,
        )
        return updated

    def assert_invalid(self, before: dict, after: dict, message: str) -> None:
        with self.assertRaisesRegex(checker.LockUpdateError, message):
            checker.validate_update(before, after)

    def test_identical_lock_is_valid_for_noop_simulation(self) -> None:
        lock = self.lock()
        self.assertEqual(
            (self.OLD_REV, self.OLD_REV),
            checker.validate_update(lock, copy.deepcopy(lock)),
        )

    def test_policy_revision_update_is_valid(self) -> None:
        before = self.lock()
        self.assertEqual(
            (self.OLD_REV, self.NEW_REV),
            checker.validate_update(before, self.update_policy(before)),
        )

    def test_policy_exclusive_dependency_change_is_valid(self) -> None:
        before = self.lock()
        after = self.update_policy(before)
        after["nodes"]["opencodePolicy"]["inputs"]["tool"] = "policyTool"
        after["nodes"]["policyTool"] = {
            "inputs": {"leaf": "policyLeaf"},
            "locked": {"rev": "3" * 40},
        }
        after["nodes"]["policyLeaf"] = {"locked": {"rev": "4" * 40}}
        checker.validate_update(before, after)

    def test_policy_exclusive_dependency_removal_is_valid(self) -> None:
        before = self.lock()
        before["nodes"]["opencodePolicy"]["inputs"]["tool"] = "policyTool"
        before["nodes"]["policyTool"] = {
            "inputs": {"leaf": "policyLeaf"},
            "locked": {"rev": "3" * 40},
        }
        before["nodes"]["policyLeaf"] = {"locked": {"rev": "4" * 40}}
        after = self.update_policy(before)
        del after["nodes"]["opencodePolicy"]["inputs"]["tool"]
        del after["nodes"]["policyTool"]
        del after["nodes"]["policyLeaf"]
        checker.validate_update(before, after)

    def test_nested_follows_shared_dependency_change_is_rejected(self) -> None:
        before = self.lock(unrelated=True)
        before["nodes"]["other"]["inputs"] = {"tool": "sharedTool"}
        before["nodes"]["opencodePolicy"]["inputs"]["tool"] = ["other", "tool"]
        before["nodes"]["sharedTool"] = {"locked": {"rev": "5" * 40}}
        after = self.update_policy(before)
        after["nodes"]["sharedTool"]["locked"]["rev"] = "6" * 40
        self.assert_invalid(before, after, "shared")

    def test_exclusive_dependency_becoming_shared_is_rejected(self) -> None:
        before = self.lock(unrelated=True)
        before["nodes"]["opencodePolicy"]["inputs"]["tool"] = "policyTool"
        before["nodes"]["policyTool"] = {"locked": {"rev": "7" * 40}}
        after = self.update_policy(before)
        after["nodes"]["other"]["inputs"] = {"tool": "policyTool"}
        self.assert_invalid(before, after, "consumer-owned")

    def test_root_nixpkgs_change_is_rejected(self) -> None:
        before = self.lock()
        after = self.update_policy(before)
        after["nodes"]["nixpkgs"]["locked"]["rev"] = "8" * 40
        self.assert_invalid(before, after, "nixpkgs|shared")

    def test_root_inputs_change_is_rejected(self) -> None:
        before = self.lock()
        after = self.update_policy(before)
        after["nodes"]["root"]["inputs"]["unexpected"] = "unexpected"
        after["nodes"]["unexpected"] = {"locked": {"rev": "9" * 40}}
        self.assert_invalid(before, after, "root node or root inputs changed")

    def test_unrelated_root_dependency_change_is_rejected(self) -> None:
        before = self.lock(unrelated=True)
        after = self.update_policy(before)
        after["nodes"]["other"]["locked"]["rev"] = "a" * 40
        self.assert_invalid(before, after, "consumer-owned")

    def test_duplicate_json_keys_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "flake.lock"
            path.write_text('{"version": 7, "version": 8}', encoding="utf-8")
            with self.assertRaisesRegex(checker.LockUpdateError, "duplicate JSON key"):
                checker.load_lock(path)


if __name__ == "__main__":
    unittest.main()
