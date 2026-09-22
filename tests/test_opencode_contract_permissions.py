from __future__ import annotations

import json
import re
import tomllib
import unittest
from collections.abc import Mapping
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "packages/opencode/config"
MANIFEST = CONFIG / "opencode-contract-permissions.toml"
LOCK = ROOT / "flake.lock"
EXPECTED_CONTRACT_REVISION = "edbe4e553e8de183acc11578dd485a5f97917338"

SURFACES = (
    "build",
    "architect",
    "general",
    "explore",
    "verifier",
    "reviewer",
    "investigator",
    "security-reviewer",
    "scout",
)
LEAVES = SURFACES[1:]
MANDATORY_CLASSES = {
    "local-filesystem-delete",
    "repository-history-destruction",
    "remote-destructive-operation",
    "privilege-escalation",
    "system-store-destruction",
}

BUILD_LOCAL_DELETE = (
    "rm generated.tmp",
    "rm -f generated.tmp",
    "rm -r build/cache",
    "rm -rf build/cache",
    "rmdir empty-generated-dir",
    "rm -rf .build/default",
)
OUT_OF_AUTHORITY_DELETE = (
    "rm /tmp/outside",
    "rm -rf /tmp/outside",
    "rm -rf ../outside",
    "rm -rf .git",
    "rm -rf $HOME/outside",
    "rm -rf ~/outside",
    "rm .",
    "rm ..",
)
COMPOSED_DELETE = (
    "rm generated.tmp; git reset --hard HEAD",
    "rm generated.tmp && git clean -fd",
    "rm generated.tmp | cat",
    "rm generated.tmp > /tmp/out",
    "rm generated.tmp < /dev/null",
    "rm $(printf generated.tmp)",
)
STRUCTURAL = (
    "git reset --hard HEAD",
    "git clean -fd",
    "git push --force origin main",
    "git push origin --delete issue-52-test",
    "sudo rm -rf /tmp/dotnix-52",
    "nix store delete /nix/store/example",
)
SAFE_READS = (
    "git -C . status --short",
    "git --no-pager status --short",
    "git -c color.ui=false status --short",
    "command -v git",
)
NORMAL_SCRIPT_EXECUTION = (
    "python3 tests/test_opencode_contract_permissions.py",
    "bash scripts/check.sh",
    "node scripts/check.js",
)
ASK_MUTATIONS = (
    "cp source.txt copy.txt",
    "mv old.txt new.txt",
    "mkdir generated",
    "touch generated.flag",
    "sed -i 's/old/new/' file.txt",
)
VALIDATION_ALLOW = (
    "pytest -q",
    "python -m pytest -q",
    "python3 -m unittest discover -s tests",
    "ruff check .",
    "python -m ruff check .",
    "mypy src",
    "python3 -m mypy src",
    "npm ci",
    "npm test",
    "npm run test",
    "npm run lint",
    "npm run typecheck",
    "npm run check",
)


def _frontmatter_bash_permission(path: Path) -> Any:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, flags=re.DOTALL)
    if match is None:
        raise AssertionError(f"missing frontmatter: {path}")

    lines = match.group(1).splitlines()
    in_permission = False
    bash_index: int | None = None
    for index, line in enumerate(lines):
        if line == "permission:":
            in_permission = True
            continue
        if in_permission and line and not line.startswith(" "):
            break
        if in_permission and line.startswith("  bash:"):
            bash_index = index
            break

    if bash_index is None:
        return None

    _, _, scalar = lines[bash_index].strip().partition(":")
    scalar = scalar.strip()
    if scalar:
        return scalar.strip("\"'")

    mapping: dict[str, str] = {}
    for line in lines[bash_index + 1 :]:
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent <= 2:
            break
        key_text, separator, value_text = line.strip().partition(":")
        if not separator:
            raise AssertionError(f"invalid bash permission line: {line!r}")
        key_text = key_text.strip()
        if key_text.startswith('"'):
            key = json.loads(key_text)
        elif key_text.startswith("'") and key_text.endswith("'"):
            key = key_text[1:-1].replace("''", "'")
        else:
            key = key_text
        mapping[key] = value_text.strip().strip("\"'")
    return mapping


def _wildcard_match(pattern: str, value: str) -> bool:
    pi = 0
    vi = 0
    star = -1
    star_vi = 0
    while vi < len(value):
        if pi < len(pattern) and (
            pattern[pi] == "?" or pattern[pi] == value[vi]
        ):
            pi += 1
            vi += 1
        elif pi < len(pattern) and pattern[pi] == "*":
            star = pi
            star_vi = vi
            pi += 1
        elif star >= 0:
            pi = star + 1
            star_vi += 1
            vi = star_vi
        else:
            return False
    while pi < len(pattern) and pattern[pi] == "*":
        pi += 1
    return pi == len(pattern)


def _layer_action(layer: Any, tool: str, input_value: str) -> tuple[str | None, bool]:
    if layer is None:
        return None, False
    if isinstance(layer, str):
        return layer, True
    if not isinstance(layer, Mapping):
        return None, False

    action: str | None = None
    matched = False
    for permission_pattern, configured in layer.items():
        if not isinstance(permission_pattern, str):
            continue
        if not _wildcard_match(permission_pattern, tool):
            continue
        if isinstance(configured, str):
            action = configured
            matched = True
            continue
        if not isinstance(configured, Mapping):
            continue
        for input_pattern, configured_action in configured.items():
            if (
                isinstance(input_pattern, str)
                and isinstance(configured_action, str)
                and _wildcard_match(input_pattern, input_value)
            ):
                action = configured_action
                matched = True
    return action, matched


def _effective_action(base: Any, agent: Any, tool: str, input_value: str) -> str | None:
    action: str | None = None
    matched = False
    for layer in (base, agent):
        layer_action, layer_matched = _layer_action(layer, tool, input_value)
        if layer_matched:
            action = layer_action
            matched = True
    return action if matched else None


class OpenCodeContractPermissionsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.config = json.loads((CONFIG / "opencode.json").read_text(encoding="utf-8"))
        cls.manifest = tomllib.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.surfaces = {item["id"]: item for item in cls.manifest["surfaces"]}
        cls.probes: dict[str, list[dict[str, Any]]] = {surface: [] for surface in SURFACES}
        for probe in cls.manifest["probes"]:
            cls.probes[probe["surface"]].append(probe)

    def permissions_for(self, surface: str) -> tuple[dict[str, Any], Any]:
        definition = self.surfaces[surface]
        return (
            self.config["permission"],
            _frontmatter_bash_permission(CONFIG / definition["agent_source"]),
        )

    def action(self, surface: str, command: str) -> str | None:
        base, agent_bash = self.permissions_for(surface)
        agent = None if agent_bash is None else {"bash": agent_bash}
        return _effective_action(base, agent, "bash", command)

    def test_contract_pin_is_exact(self) -> None:
        lock = json.loads(LOCK.read_text(encoding="utf-8"))
        node = lock["nodes"]["opencodeContract"]["locked"]
        self.assertEqual(node["rev"], EXPECTED_CONTRACT_REVISION)
        self.assertEqual(node["owner"], "upiscium")
        self.assertEqual(node["repo"], "OpencodeContract")

    def test_manifest_has_exact_surfaces_and_mandatory_coverage(self) -> None:
        self.assertEqual(set(self.surfaces), set(SURFACES))
        self.assertEqual(self.surfaces["build"]["boundary"], "parent")
        self.assertEqual(self.surfaces["build"]["signals"], [])
        for leaf in LEAVES:
            with self.subTest(leaf=leaf):
                self.assertEqual(self.surfaces[leaf]["boundary"], "leaf")
                self.assertEqual(
                    set(self.surfaces[leaf]["signals"]),
                    {"NEEDS_APPROVAL", "NEEDS_DECISION"},
                )
        for surface in SURFACES:
            with self.subTest(surface=surface):
                covered = {
                    class_id
                    for probe in self.probes[surface]
                    for class_id in probe["classes"]
                }
                self.assertTrue(MANDATORY_CLASSES <= covered)
                self.assertNotIn("safe-read-only", covered)

    def test_build_direct_local_delete_is_ask_not_allow(self) -> None:
        for command in BUILD_LOCAL_DELETE:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "ask")
                self.assertNotEqual(self.action("build", command), "allow")

    def test_out_of_authority_delete_is_denied(self) -> None:
        for command in OUT_OF_AUTHORITY_DELETE:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "deny")

    def test_composed_delete_does_not_bypass_boundary(self) -> None:
        for command in COMPOSED_DELETE:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "deny")

    def test_leaf_local_delete_is_denied(self) -> None:
        for leaf in LEAVES:
            for command in BUILD_LOCAL_DELETE:
                with self.subTest(leaf=leaf, command=command):
                    self.assertEqual(self.action(leaf, command), "deny")

    def test_structural_remote_privilege_and_store_destruction_remain_denied(self) -> None:
        for surface in SURFACES:
            for command in STRUCTURAL:
                with self.subTest(surface=surface, command=command):
                    self.assertEqual(self.action(surface, command), "deny")

    def test_existing_safe_read_variants_are_preserved(self) -> None:
        for command in SAFE_READS:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "allow")

    def test_normal_script_execution_is_not_newly_hard_denied(self) -> None:
        for command in NORMAL_SCRIPT_EXECUTION:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "ask")

    def test_common_local_mutations_are_ask(self) -> None:
        for command in ASK_MUTATIONS:
            with self.subTest(command=command):
                self.assertEqual(self.action("build", command), "ask")

    def test_validation_commands_are_allow_for_build_and_verifier(self) -> None:
        for surface in ("build", "verifier"):
            for command in VALIDATION_ALLOW:
                with self.subTest(surface=surface, command=command):
                    self.assertEqual(self.action(surface, command), "allow")

    def test_leaf_prompts_keep_noninteractive_escalation_contract(self) -> None:
        for leaf in LEAVES:
            with self.subTest(leaf=leaf):
                text = (CONFIG / self.surfaces[leaf]["agent_source"]).read_text(
                    encoding="utf-8"
                )
                self.assertIn("NEEDS_APPROVAL", text)
                self.assertIn("NEEDS_DECISION", text)
                self.assertIn("Do not ask the user", text)


if __name__ == "__main__":
    unittest.main()
