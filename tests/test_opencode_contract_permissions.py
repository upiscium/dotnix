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
MANIFEST_PATH = CONFIG / "opencode-contract-permissions.toml"
LOCK_PATH = ROOT / "flake.lock"
EXPECTED_CONTRACT_REVISION = "edbe4e553e8de183acc11578dd485a5f97917338"

SURFACE_IDS = (
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
LEAF_IDS = SURFACE_IDS[1:]
MANDATORY_CLASSES = {
    "local-filesystem-delete",
    "repository-history-destruction",
    "remote-destructive-operation",
    "privilege-escalation",
    "system-store-destruction",
}
LOCAL_INPUTS = (
    "rm generated.tmp",
    "rm -f generated.tmp",
    "rm -r build/cache",
    "rm -rf build/cache",
    "rmdir empty-generated-dir",
    "rm -rf .build/default",
    "rm -r .build/default",
    "rmdir .build/default",
)
BASE_PROBE_CLASS_BY_INPUT = {
    **{input_value: "local-filesystem-delete" for input_value in LOCAL_INPUTS},
    "git reset --hard HEAD": "repository-history-destruction",
    "git clean -fd": "repository-history-destruction",
    "git push --force origin main": "remote-destructive-operation",
    "git push origin --delete issue-52-test": "remote-destructive-operation",
    "sudo rm -rf /tmp/dotnix-52": "privilege-escalation",
    "nix store delete /nix/store/example": "system-store-destruction",
}
EXTRA_PROBE_CLASS_BY_SURFACE = {
    "build": {
        "git branch -D issue-52-test": "repository-history-destruction",
        "git tag -d issue-52-test": "repository-history-destruction",
        "git stash drop stash@{0}": "repository-history-destruction",
        "git stash clear": "repository-history-destruction",
        "git worktree remove .worktrees/test": "repository-history-destruction",
        "git worktree prune": "repository-history-destruction",
        "gh pr merge 52 --delete-branch": "remote-destructive-operation",
    },
    "verifier": {
        "git branch -D issue-52-test": "repository-history-destruction",
        "git tag -d issue-52-test": "repository-history-destruction",
        "git stash drop stash@{0}": "repository-history-destruction",
        "git stash clear": "repository-history-destruction",
        "git worktree remove .worktrees/test": "repository-history-destruction",
        "git worktree prune": "repository-history-destruction",
        "gh pr merge 52 --delete-branch": "remote-destructive-operation",
    },
}
SHELL_COMPOSITION_INPUTS = (
    "git status; rm -rf /tmp/dotnix-52",
    "git diff && git clean -fd",
    "ls || sudo rm -rf /tmp/dotnix-52",
    "git status | nix store delete /nix/store/example",
    "opencode $(rm -rf /tmp/dotnix-52)",
    "git status `sudo rm -rf /tmp/dotnix-52`",
    "git status > /tmp/dotnix-52-output",
    "git status\nrm -rf /tmp/dotnix-52",
    "env git branch -D issue-52-test",
    "bash -c 'git branch -D issue-52-test'",
    "sh -c 'rm -rf /tmp/dotnix-52'",
    "git -C . branch -D issue-52-test",
    "git -C . reset --hard HEAD",
    "git -c core.fsmonitor=./evil clean -fd",
    "git diff --no-index /dev/null ./payload --output=/tmp/dotnix-52-output",
    "git diff-tree HEAD --output=/tmp/dotnix-52-output",
    "git diff-index HEAD --output=/tmp/dotnix-52-output",
    "git log --output=/tmp/dotnix-52-output",
    "git show HEAD --output=/tmp/dotnix-52-output",
    "git stash list -p --output=/tmp/dotnix-52-output",
    "git stash show --output=/tmp/dotnix-52-output",
    "git reflog show -p --output=/tmp/dotnix-52-output",
    "eval 'rm -rf /tmp/dotnix-52'",
    "exec git branch -D issue-52-test",
)
SAFE_READ_INPUTS = (
    "git status --short",
    "git --no-pager status --short",
    "git -C /tmp/dotnix-repo status --short",
    "git -c core.fsmonitor=true status --short",
    "command -v git",
)
STRUCTURAL_INPUTS = tuple(
    input_value
    for input_value in {
        *BASE_PROBE_CLASS_BY_INPUT,
        *(
            input_value
            for extra in EXTRA_PROBE_CLASS_BY_SURFACE.values()
            for input_value in extra
        ),
    }
    if input_value not in LOCAL_INPUTS
)


def _frontmatter(text: str) -> str:
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, flags=re.DOTALL)
    if match is None:
        raise AssertionError("missing frontmatter")
    return match.group(1)


def _indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def _scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        decoded = json.loads(value)
        if not isinstance(decoded, str):
            raise AssertionError(f"frontmatter value is not a string: {value}")
        return decoded
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    return value


def _mapping(
    lines: list[str], start: int, base_indent: int
) -> tuple[dict[str, Any], int]:
    result: dict[str, Any] = {}
    index = start
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        current_indent = _indent(line)
        if current_indent < base_indent:
            break
        if current_indent != base_indent:
            raise AssertionError(f"unexpected frontmatter indentation: {line!r}")

        key_text, separator, value_text = line.strip().partition(":")
        if not separator:
            raise AssertionError(f"invalid frontmatter mapping line: {line!r}")
        key = _scalar(key_text)
        if key in result:
            raise AssertionError(f"duplicate frontmatter key: {key}")
        value = value_text.strip()
        if value:
            result[key] = _scalar(value)
            index += 1
            continue

        index += 1
        next_content = index
        while next_content < len(lines) and not lines[next_content].strip():
            next_content += 1
        if next_content >= len(lines) or _indent(lines[next_content]) <= current_indent:
            result[key] = {}
            continue
        result[key], index = _mapping(
            lines, next_content, _indent(lines[next_content])
        )
    return result, index


def _frontmatter_permissions(path: Path) -> dict[str, Any]:
    block = _frontmatter(path.read_text(encoding="utf-8"))
    lines = block.splitlines()
    for index, line in enumerate(lines):
        if _indent(line) == 0 and line.strip() == "permission:":
            permissions, _ = _mapping(lines, index + 1, 2)
            return permissions
    raise AssertionError(f"missing permission frontmatter: {path}")


def _wildcard_match(pattern: str, value: str) -> bool:
    pattern_index = 0
    value_index = 0
    last_star = -1
    star_value_index = 0

    while value_index < len(value):
        if pattern_index < len(pattern) and (
            pattern[pattern_index] == "?"
            or pattern[pattern_index] == value[value_index]
        ):
            pattern_index += 1
            value_index += 1
        elif pattern_index < len(pattern) and pattern[pattern_index] == "*":
            last_star = pattern_index
            star_value_index = value_index
            pattern_index += 1
        elif last_star >= 0:
            pattern_index = last_star + 1
            star_value_index += 1
            value_index = star_value_index
        else:
            return False

    while pattern_index < len(pattern) and pattern[pattern_index] == "*":
        pattern_index += 1
    return pattern_index == len(pattern)


def _layer_action(
    layer: Any, tool: str, input_value: str
) -> tuple[str | None, bool]:
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


def _effective_action(
    base_permission: Any,
    agent_permission: Any,
    tool: str,
    input_value: str,
) -> str | None:
    action: str | None = None
    matched = False
    for layer in (base_permission, agent_permission):
        layer_action, layer_matched = _layer_action(layer, tool, input_value)
        if layer_matched:
            action = layer_action
            matched = True
    return action if matched else None


class OpenCodeContractPermissionsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = tomllib.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    def surfaces(self) -> dict[str, dict[str, Any]]:
        return {surface["id"]: surface for surface in self.manifest["surfaces"]}

    def probes(self) -> dict[str, list[dict[str, Any]]]:
        by_surface = {surface_id: [] for surface_id in SURFACE_IDS}
        for probe in self.manifest["probes"]:
            by_surface.setdefault(probe["surface"], []).append(probe)
        return by_surface

    def expected_probe_classes(self, surface_id: str) -> dict[str, str]:
        return {
            **BASE_PROBE_CLASS_BY_INPUT,
            **EXTRA_PROBE_CLASS_BY_SURFACE.get(surface_id, {}),
        }

    def source_permissions(
        self, surface: Mapping[str, Any]
    ) -> tuple[dict[str, Any], dict[str, Any]]:
        base_path = CONFIG / surface["base_source"]
        base_document = json.loads(base_path.read_text(encoding="utf-8"))
        self.assertIsInstance(base_document, dict)
        base_permission = base_document.get("permission")
        self.assertIsInstance(base_permission, dict)

        agent_path = CONFIG / surface["agent_source"]
        agent_permission = _frontmatter_permissions(agent_path)
        self.assertIsInstance(agent_permission, dict)
        return base_permission, agent_permission

    def test_manifest_has_closed_schema_and_exact_surface_set(self) -> None:
        self.assertEqual(
            set(self.manifest),
            {"schema_version", "contract", "profile", "surfaces", "probes"},
        )
        self.assertEqual(self.manifest["schema_version"], 1)
        self.assertEqual(self.manifest["contract"], "permission-semantics")
        self.assertEqual(self.manifest["profile"], "global")

        surfaces = self.manifest["surfaces"]
        self.assertEqual([surface["id"] for surface in surfaces], list(SURFACE_IDS))
        self.assertEqual(set(self.surfaces()), set(SURFACE_IDS))
        for surface_id in SURFACE_IDS:
            with self.subTest(surface=surface_id):
                surface = self.surfaces()[surface_id]
                self.assertEqual(
                    set(surface),
                    {"id", "boundary", "base_source", "agent_source", "signals"},
                )
                expected_boundary = "parent" if surface_id == "build" else "leaf"
                self.assertEqual(surface["boundary"], expected_boundary)
                self.assertEqual(surface["base_source"], "opencode.json")
                self.assertEqual(
                    surface["agent_source"], f"agents/{surface_id}.md"
                )
                expected_signals = (
                    []
                    if surface_id == "build"
                    else ["NEEDS_APPROVAL", "NEEDS_DECISION"]
                )
                self.assertEqual(surface["signals"], expected_signals)

        self.assertNotIn("plan", self.surfaces())
        self.assertFalse(
            set(self.surfaces())
            & {"local-investigator", "local-tracer", "local-background"}
        )

    def test_probes_have_closed_schema_exact_inputs_and_full_coverage(self) -> None:
        probes = self.probes()
        self.assertEqual(
            len(self.manifest["probes"]),
            len(SURFACE_IDS) * len(BASE_PROBE_CLASS_BY_INPUT)
            + sum(len(extra) for extra in EXTRA_PROBE_CLASS_BY_SURFACE.values()),
        )
        for probe in self.manifest["probes"]:
            with self.subTest(probe=probe):
                self.assertEqual(
                    set(probe), {"surface", "tool", "input", "classes"}
                )
                self.assertIn(probe["surface"], SURFACE_IDS)
                self.assertEqual(probe["tool"], "bash")
                self.assertIn(
                    probe["input"], self.expected_probe_classes(probe["surface"])
                )
                self.assertEqual(
                    probe["classes"],
                    [self.expected_probe_classes(probe["surface"])[probe["input"]]],
                )
                self.assertNotIn("safe-read-only", probe["classes"])

        for surface_id in SURFACE_IDS:
            with self.subTest(surface=surface_id):
                surface_inputs = {probe["input"] for probe in probes[surface_id]}
                self.assertEqual(
                    surface_inputs, set(self.expected_probe_classes(surface_id))
                )
                covered = {
                    class_id
                    for probe in probes[surface_id]
                    for class_id in probe["classes"]
                }
                self.assertTrue(MANDATORY_CLASSES <= covered)

    def test_manifest_sources_are_actual_json_and_frontmatter_sources(self) -> None:
        for surface_id, surface in self.surfaces().items():
            with self.subTest(surface=surface_id):
                base_permission, agent_permission = self.source_permissions(surface)
                self.assertIsInstance(base_permission, dict)
                self.assertIsInstance(agent_permission, dict)

    def test_contract_lock_is_pinned_to_the_required_revision(self) -> None:
        lock = json.loads(LOCK_PATH.read_text(encoding="utf-8"))
        contract_node = lock["nodes"]["opencodeContract"]
        self.assertEqual(
            contract_node["locked"]["rev"], EXPECTED_CONTRACT_REVISION
        )
        self.assertEqual(contract_node["locked"]["owner"], "upiscium")
        self.assertEqual(contract_node["locked"]["repo"], "OpencodeContract")
        self.assertEqual(contract_node["locked"]["type"], "github")

    def test_build_direct_local_delete_resolves_ask_without_cache_special_case(
        self,
    ) -> None:
        surface = self.surfaces()["build"]
        base_permission, agent_permission = self.source_permissions(surface)
        base_bash = base_permission["bash"]
        self.assertEqual(base_bash["rm*"], "deny")
        self.assertEqual(base_bash["rm -rf*"], "deny")
        self.assertEqual(base_bash["rm *"], "ask")
        self.assertEqual(base_bash["rmdir *"], "ask")
        self.assertNotIn("bash", agent_permission)

        for probe in self.probes()["build"]:
            if probe["input"] in LOCAL_INPUTS:
                with self.subTest(input=probe["input"]):
                    action = _effective_action(
                        base_permission,
                        agent_permission,
                        probe["tool"],
                        probe["input"],
                    )
                    self.assertEqual(action, "ask")
                    self.assertNotEqual(action, "allow")

        permission_keys = list(base_bash)
        for ask_pattern in ("rm *", "rmdir *"):
            with self.subTest(pattern=ask_pattern):
                self.assertLess(
                    permission_keys.index(ask_pattern),
                    permission_keys.index("*;*"),
                )

    def test_safe_read_allowlist_remains_explicit(self) -> None:
        surface = self.surfaces()["build"]
        base_permission, agent_permission = self.source_permissions(surface)
        for input_value in SAFE_READ_INPUTS:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "allow",
                )

    def test_safe_git_wrappers_remain_read_only_and_destructive_forms_deny(self) -> None:
        surface = self.surfaces()["build"]
        base_permission, agent_permission = self.source_permissions(surface)
        for input_value in SAFE_READ_INPUTS[2:4]:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "allow",
                )
        for input_value in (
            "git -C . reset --hard HEAD",
            "git -c core.fsmonitor=./evil clean -fd",
        ):
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "deny",
                )

    def test_all_leaf_probes_resolve_deny(self) -> None:
        for surface_id in LEAF_IDS:
            surface = self.surfaces()[surface_id]
            base_permission, agent_permission = self.source_permissions(surface)
            for probe in self.probes()[surface_id]:
                with self.subTest(surface=surface_id, input=probe["input"]):
                    self.assertEqual(
                        _effective_action(
                            base_permission,
                            agent_permission,
                            probe["tool"],
                            probe["input"],
                        ),
                        "deny",
                    )

    def test_leaf_needs_approval_is_declared_and_local_delete_never_asks(self) -> None:
        for surface_id in LEAF_IDS:
            with self.subTest(surface=surface_id):
                surface = self.surfaces()[surface_id]
                self.assertIn("NEEDS_APPROVAL", surface["signals"])
                self.assertEqual(
                    surface["signals"], ["NEEDS_APPROVAL", "NEEDS_DECISION"]
                )
                base_permission, agent_permission = self.source_permissions(surface)
                for probe in self.probes()[surface_id]:
                    if probe["input"] in LOCAL_INPUTS:
                        action = _effective_action(
                            base_permission,
                            agent_permission,
                            probe["tool"],
                            probe["input"],
                        )
                        self.assertNotIn(action, {"ask", "allow"})
                        self.assertEqual(action, "deny")

    def test_leaf_prompts_retain_the_non_interactive_return_contract(self) -> None:
        required_statuses = {
            "COMPLETED",
            "BLOCKED",
            "NEEDS_APPROVAL",
            "NEEDS_DECISION",
        }
        for surface_id in LEAF_IDS:
            with self.subTest(surface=surface_id):
                prompt = (
                    CONFIG / self.surfaces()[surface_id]["agent_source"]
                ).read_text(encoding="utf-8")
                status_line = next(
                    line for line in prompt.splitlines()
                    if line.startswith("Start the final response with exactly one of:")
                )
                self.assertTrue(
                    required_statuses <= set(re.findall(r"status: ([A-Z_]+)", status_line))
                )
                self.assertIn("Do not ask the user", prompt)
                self.assertIn("delegate", prompt)

    def test_structural_probes_remain_deny_on_parent_and_leaves(self) -> None:
        for surface_id in SURFACE_IDS:
            surface = self.surfaces()[surface_id]
            base_permission, agent_permission = self.source_permissions(surface)
            for probe in self.probes()[surface_id]:
                if probe["input"] in STRUCTURAL_INPUTS:
                    with self.subTest(surface=surface_id, input=probe["input"]):
                        self.assertEqual(
                            _effective_action(
                                base_permission,
                                agent_permission,
                                probe["tool"],
                                probe["input"],
                            ),
                            "deny",
                        )

    def test_shell_composition_cannot_bypass_destructive_denies(self) -> None:
        for surface_id in SURFACE_IDS:
            surface = self.surfaces()[surface_id]
            base_permission, agent_permission = self.source_permissions(surface)
            for input_value in SHELL_COMPOSITION_INPUTS:
                with self.subTest(surface=surface_id, input=input_value):
                    self.assertEqual(
                        _effective_action(
                            base_permission,
                            agent_permission,
                            "bash",
                            input_value,
                        ),
                        "deny",
                    )

    def test_verifier_later_rm_deny_overrides_bash_wildcard_ask(self) -> None:
        surface = self.surfaces()["verifier"]
        _, agent_permission = self.source_permissions(surface)
        verifier_bash = agent_permission["bash"]
        self.assertEqual(verifier_bash["*"], "ask")
        self.assertEqual(verifier_bash["rm*"], "deny")
        self.assertLess(
            list(verifier_bash).index("*"), list(verifier_bash).index("rm*")
        )

        base_permission, agent_permission = self.source_permissions(surface)
        for input_value in LOCAL_INPUTS:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "deny",
                )


if __name__ == "__main__":
    unittest.main()
