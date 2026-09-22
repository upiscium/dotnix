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
OUT_OF_AUTHORITY_LOCAL_INPUTS = (
    "rm -rf /",
    "rm -rf /tmp/dotnix-52",
    "rmdir /tmp/dotnix-52",
    "rm -rf ../outside",
    'rm -rf "$HOME"/outside',
    "rm -rf ~",
    "rm -rf .",
    "rm -rf ..",
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
        "git update-ref -d refs/heads/main": "repository-history-destruction",
        "git remote set-head origin -d": "repository-history-destruction",
        "git remote set-head origin --delete": "repository-history-destruction",
        "git remote prune origin": "repository-history-destruction",
        "git remote update --prune origin": "repository-history-destruction",
        "git remote update -p origin": "repository-history-destruction",
        "git remote remove origin": "repository-history-destruction",
        "git remote rm origin": "repository-history-destruction",
        "git fetch --prune origin": "repository-history-destruction",
        "git fetch -p origin": "repository-history-destruction",
        "git prune --expire now": "repository-history-destruction",
        "git gc --prune=now": "repository-history-destruction",
        "git gc": "repository-history-destruction",
        "git gc --auto": "repository-history-destruction",
        "git maintenance run --task=gc": "repository-history-destruction",
        "git notes remove HEAD": "repository-history-destruction",
        "git notes prune": "repository-history-destruction",
        'git remote "$MODE" origin': "repository-history-destruction",
        'git maintenance run --task="$TASK"': "repository-history-destruction",
        'git notes "$MODE" HEAD': "repository-history-destruction",
        'git fetch "$PRUNE" origin': "repository-history-destruction",
        'git fetch origin "$REF"': "repository-history-destruction",
        "git fetch -qpf origin": "repository-history-destruction",
        "git --git-dir=.git remote prune origin": "repository-history-destruction",
        "git --work-tree=. fetch --prune origin": "repository-history-destruction",
        "git --git-dir .git notes remove HEAD": "repository-history-destruction",
        "git --work-tree . gc": "repository-history-destruction",
        "git\tremote remove origin": "repository-history-destruction",
        "git\tnotes remove HEAD": "repository-history-destruction",
        "git\tfetch -p origin": "repository-history-destruction",
        'git\tfetch "$PRUNE" origin': "repository-history-destruction",
        "git\tremote update --prune origin": "repository-history-destruction",
        "git\tremote set-head origin -d": "repository-history-destruction",
        "git\tmaintenance run --task=gc": "repository-history-destruction",
        "git\tfetch -qpf origin": "repository-history-destruction",
        "git fetch -P origin": "repository-history-destruction",
        "git fetch -qp origin": "repository-history-destruction",
        "git fetch -fp origin": "repository-history-destruction",
        "git fetch -vp origin": "repository-history-destruction",
        "git fetch -np origin": "repository-history-destruction",
        'git\tremote "$MODE" origin': "repository-history-destruction",
        "git symbolic-ref --delete refs/remotes/origin/HEAD": "repository-history-destruction",
        "git replace -d deadbeef": "repository-history-destruction",
        "git branch -vv -f feature HEAD": "repository-history-destruction",
        "git branch -f feature HEAD": "repository-history-destruction",
        "git branch --verbose --force feature HEAD": "repository-history-destruction",
        "git branch -M old new": "repository-history-destruction",
        "git branch -m old new": "repository-history-destruction",
        "git branch -c old new": "repository-history-destruction",
        "git\tbranch\t-D issue-52-test": "repository-history-destruction",
        "git${IFS}branch${IFS}-D issue-52-test": "repository-history-destruction",
        "git tag -f release HEAD": "repository-history-destruction",
        "git tag --force release HEAD": "repository-history-destruction",
        "git fsck --lost-found": "repository-history-destruction",
        "git fsck \"--lost-found\"": "repository-history-destruction",
        "git fsck \"$FSCK_MODE\"": "repository-history-destruction",
        "git checkout -B feature HEAD": "repository-history-destruction",
        "git switch -C feature HEAD": "repository-history-destruction",
        "git branch \"$MODE\" feature HEAD": "repository-history-destruction",
        "git checkout \"$MODE\" feature HEAD": "repository-history-destruction",
        "git switch \"$MODE\" feature": "repository-history-destruction",
        "git tag \"$MODE\" release HEAD": "repository-history-destruction",
        "gh pr merge 52 --delete-branch": "remote-destructive-operation",
        "git push origin +feature:feature": "remote-destructive-operation",
        "git push origin \"$REF\"": "remote-destructive-operation",
        "git push origin \\:issue-52-test": "remote-destructive-operation",
        "git send-pack --force origin refs/heads/main:refs/heads/main": "remote-destructive-operation",
        "/usr/bin/git push origin :issue-52-test": "remote-destructive-operation",
        "/usr/bin/git\tpush\t:issue-52-test": "remote-destructive-operation",
        "git${IFS}push${IFS}:issue-52-test": "remote-destructive-operation",
        "doas id": "privilege-escalation",
        "pkexec id": "privilege-escalation",
        "su -c id": "privilege-escalation",
        "runuser -u root id": "privilege-escalation",
        "su --command=id": "privilege-escalation",
        "nix-collect-garbage -d": "system-store-destruction",
    },
    "verifier": {
        "git branch -D issue-52-test": "repository-history-destruction",
        "git tag -d issue-52-test": "repository-history-destruction",
        "git stash drop stash@{0}": "repository-history-destruction",
        "git stash clear": "repository-history-destruction",
        "git worktree remove .worktrees/test": "repository-history-destruction",
        "git worktree prune": "repository-history-destruction",
        "git update-ref -d refs/heads/main": "repository-history-destruction",
        "git remote set-head origin -d": "repository-history-destruction",
        "git remote set-head origin --delete": "repository-history-destruction",
        "git remote prune origin": "repository-history-destruction",
        "git remote update --prune origin": "repository-history-destruction",
        "git remote update -p origin": "repository-history-destruction",
        "git remote remove origin": "repository-history-destruction",
        "git remote rm origin": "repository-history-destruction",
        "git fetch --prune origin": "repository-history-destruction",
        "git fetch -p origin": "repository-history-destruction",
        "git prune --expire now": "repository-history-destruction",
        "git gc --prune=now": "repository-history-destruction",
        "git gc": "repository-history-destruction",
        "git gc --auto": "repository-history-destruction",
        "git maintenance run --task=gc": "repository-history-destruction",
        "git notes remove HEAD": "repository-history-destruction",
        "git notes prune": "repository-history-destruction",
        'git remote "$MODE" origin': "repository-history-destruction",
        'git maintenance run --task="$TASK"': "repository-history-destruction",
        'git notes "$MODE" HEAD': "repository-history-destruction",
        'git fetch "$PRUNE" origin': "repository-history-destruction",
        'git fetch origin "$REF"': "repository-history-destruction",
        "git fetch -qpf origin": "repository-history-destruction",
        "git --git-dir=.git remote prune origin": "repository-history-destruction",
        "git --work-tree=. fetch --prune origin": "repository-history-destruction",
        "git --git-dir .git notes remove HEAD": "repository-history-destruction",
        "git --work-tree . gc": "repository-history-destruction",
        "git\tremote remove origin": "repository-history-destruction",
        "git\tnotes remove HEAD": "repository-history-destruction",
        "git\tfetch -p origin": "repository-history-destruction",
        'git\tfetch "$PRUNE" origin': "repository-history-destruction",
        "git\tremote update --prune origin": "repository-history-destruction",
        "git\tremote set-head origin -d": "repository-history-destruction",
        "git\tmaintenance run --task=gc": "repository-history-destruction",
        "git\tfetch -qpf origin": "repository-history-destruction",
        "git fetch -P origin": "repository-history-destruction",
        "git fetch -qp origin": "repository-history-destruction",
        "git fetch -fp origin": "repository-history-destruction",
        "git fetch -vp origin": "repository-history-destruction",
        "git fetch -np origin": "repository-history-destruction",
        'git\tremote "$MODE" origin': "repository-history-destruction",
        "git symbolic-ref --delete refs/remotes/origin/HEAD": "repository-history-destruction",
        "git replace -d deadbeef": "repository-history-destruction",
        "git branch -vv -f feature HEAD": "repository-history-destruction",
        "git branch -f feature HEAD": "repository-history-destruction",
        "git branch --verbose --force feature HEAD": "repository-history-destruction",
        "git branch -M old new": "repository-history-destruction",
        "git branch -m old new": "repository-history-destruction",
        "git branch -c old new": "repository-history-destruction",
        "git\tbranch\t-D issue-52-test": "repository-history-destruction",
        "git${IFS}branch${IFS}-D issue-52-test": "repository-history-destruction",
        "git tag -f release HEAD": "repository-history-destruction",
        "git tag --force release HEAD": "repository-history-destruction",
        "git fsck --lost-found": "repository-history-destruction",
        "git fsck \"--lost-found\"": "repository-history-destruction",
        "git fsck \"$FSCK_MODE\"": "repository-history-destruction",
        "git checkout -B feature HEAD": "repository-history-destruction",
        "git switch -C feature HEAD": "repository-history-destruction",
        "git branch \"$MODE\" feature HEAD": "repository-history-destruction",
        "git checkout \"$MODE\" feature HEAD": "repository-history-destruction",
        "git switch \"$MODE\" feature": "repository-history-destruction",
        "git tag \"$MODE\" release HEAD": "repository-history-destruction",
        "gh pr merge 52 --delete-branch": "remote-destructive-operation",
        "git push origin +feature:feature": "remote-destructive-operation",
        "git push origin \"$REF\"": "remote-destructive-operation",
        "git push origin \\:issue-52-test": "remote-destructive-operation",
        "git send-pack --force origin refs/heads/main:refs/heads/main": "remote-destructive-operation",
        "/usr/bin/git push origin :issue-52-test": "remote-destructive-operation",
        "/usr/bin/git\tpush\t:issue-52-test": "remote-destructive-operation",
        "git${IFS}push${IFS}:issue-52-test": "remote-destructive-operation",
        "doas id": "privilege-escalation",
        "pkexec id": "privilege-escalation",
        "su -c id": "privilege-escalation",
        "runuser -u root id": "privilege-escalation",
        "su --command=id": "privilege-escalation",
        "nix-collect-garbage -d": "system-store-destruction",
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
    "/usr/bin/git push -f origin main",
    "git push -d origin issue-52-test",
    "/usr/bin/git\tbranch\t-D issue-52-test",
    "/usr/bin/sudo id",
    "git update-ref -d refs/heads/main",
    "git symbolic-ref --delete refs/remotes/origin/HEAD",
    "git replace -d deadbeef",
    "git branch -vv -f feature HEAD",
    "git branch -vv -M old new",
    "git\tbranch\t-vv\t-f feature HEAD",
    "git branch -f feature HEAD",
    "git branch --verbose --force feature HEAD",
    "git branch -M old new",
    "git branch -m old new",
    "git branch -c old new",
    "git branch \"-f\" feature HEAD",
    "git branch '-M' old new",
    "git${IFS}branch${IFS}-D issue-52-test",
    "git tag -f release HEAD",
    "git tag --force release HEAD",
    "git tag \"-f\" release HEAD",
    "git fsck --lost-found",
    "git fsck \"--lost-found\"",
    "git fsck \\--lost-found",
    "git fsck \"$FSCK_MODE\"",
    "git checkout -B feature HEAD",
    "git switch -C feature HEAD",
    "git branch \"$MODE\" feature HEAD",
    "git checkout \"$MODE\" feature HEAD",
    "git switch \"$MODE\" feature",
    "git tag \"$MODE\" release HEAD",
    "git push origin +feature:feature",
    "git push origin \":issue-52-test\"",
    "git push origin ':issue-52-test'",
    "git push origin \"$REF\"",
    "git push origin \\:issue-52-test",
    "git send-pack --force origin refs/heads/main:refs/heads/main",
    "/usr/bin/git push origin :issue-52-test",
    "/usr/bin/git\tpush\t:issue-52-test",
    "git${IFS}push${IFS}:issue-52-test",
    "nix-collect-garbage -d",
    "/bin/rm -rf /tmp/dotnix-52",
    "git --work-tree=. reset --hard HEAD",
    "git --work-tree=. clean -fd",
    "git --work-tree=. branch --delete issue-52-test",
    "git --work-tree=. tag --delete issue-52-test",
    "git --work-tree=. diff -o /tmp/dotnix-52-output",
    "git remote set-head origin -d",
    "git remote set-head origin --delete",
    "git remote prune origin",
    "git remote update --prune origin",
    "git remote update -p origin",
    "git remote remove origin",
    "git remote rm origin",
    "git fetch --prune origin",
    "git fetch -p origin",
    "/usr/bin/git remote prune origin",
    "/usr/bin/git remote remove origin",
    "git\tremote\tprune origin",
    "git${IFS}remote${IFS}rm origin",
    "git${IFS}fetch${IFS}--prune origin",
    "git prune --expire now",
    "git gc --prune=now",
    "git gc",
    "git gc --auto",
    "git maintenance run --task=gc",
    "git notes remove HEAD",
    "git notes prune",
    "/usr/bin/git prune --expire now",
    "/usr/bin/git notes prune",
    "/usr/bin/git gc --auto",
    "git\tprune\t--expire now",
    "git${IFS}gc${IFS}--prune=now",
    "git${IFS}maintenance${IFS}run${IFS}--task=gc",
    "git${IFS}notes${IFS}remove HEAD",
    'git remote "$MODE" origin',
    'git maintenance run --task="$TASK"',
    'git notes "$MODE" HEAD',
    'git fetch "$PRUNE" origin',
    'git fetch origin "$REF"',
    "git fetch -qpf origin",
    "git\tremote prune origin",
    "git remote\tprune origin",
    "git remote${IFS}prune origin",
    "git --git-dir=.git remote prune origin",
    "git --work-tree=. fetch --prune origin",
    "git --git-dir .git notes remove HEAD",
    "git --work-tree . gc",
    "git\tremote remove origin",
    "git remote\tremove origin",
    "git\tnotes remove HEAD",
    "git notes\tprune",
    "git\tfetch -p origin",
    'git\tfetch "$PRUNE" origin',
    "git fetch\t-p origin",
    "git\tremote update --prune origin",
    "git\tremote set-head origin -d",
    "git\tmaintenance run --task=gc",
    "git\tfetch -qpf origin",
    "FOO=bar git prune --expire now",
    "FOO=bar git gc",
    "git\treset --hard HEAD",
    "FOO=bar\tgit\treset --hard HEAD",
    "FOO=bar\trm -rf /tmp/dotnix-52",
    "/usr/bin/rm${IFS}-rf${IFS}/tmp/dotnix-52",
    "/bin/rm$IFS-rf$IFS/tmp/dotnix-52",
    "FOO=bar\tsudo id",
    "GIT_OPTIONAL_LOCKS=0 git reset --hard HEAD",
    "GIT_OPTIONAL_LOCKS=0 git clean -fd",
    "GIT_OPTIONAL_LOCKS=0 git push --mirror origin",
    "GIT_OPTIONAL_LOCKS=0 git reflog delete refs/heads/main",
    "GIT_OPTIONAL_LOCKS=0 git branch -D issue-52-test",
    "FOO=bar gh issue delete 52",
    "NIX_CONFIG=foo nix store gc",
    "FOO=bar rm -rf /tmp/dotnix-52",
    "FOO=bar bash -c 'rm -rf /tmp/dotnix-52'",
    "rm -rf .git",
    'rm -rf -- "/tmp/dotnix-52"',
    "rm -rf -- '/tmp/dotnix-52'",
    "find . -delete",
    "find\t.\t-delete",
    "unlink /tmp/dotnix-52",
    "shred /tmp/dotnix-52",
    "truncate -s 0 /tmp/dotnix-52",
    "dd if=/dev/zero of=/tmp/dotnix-52",
    "doas id",
    "pkexec id",
    "su -c id",
    "su\t-c id",
    "su --command=id",
    "runuser -u root id",
    "python3 -c '__import__(\"os\").remove(\"/tmp/dotnix-52\")'",
    "/bin/dd if=/dev/zero of=/dev/sda",
    "dd${IFS}if=/dev/zero of=/dev/sda",
    "python3 /tmp/payload.py",
    "node --eval='require(\"fs\").writeFileSync(\"/tmp/x\",\"x\")'",
    "git diff --no-index /dev/null ./payload --output=/tmp/dotnix-52-output",
    "git diff -o /tmp/dotnix-52-output",
    "git diff-tree HEAD --output=/tmp/dotnix-52-output",
    "git diff-index HEAD --output=/tmp/dotnix-52-output",
    "git log --output=/tmp/dotnix-52-output",
    "git show HEAD --output=/tmp/dotnix-52-output",
    "git stash list -p --output=/tmp/dotnix-52-output",
    "git stash show --output=/tmp/dotnix-52-output",
    "git reflog show -p --output=/tmp/dotnix-52-output",
    "git --work-tree=. log --grep=needle --output=/tmp/out",
    "git --work-tree . log --grep=needle -o /tmp/out",
    "eval 'rm -rf /tmp/dotnix-52'",
    "exec git branch -D issue-52-test",
)
VERIFIER_INHERITED_DENY_INPUTS = (
    "cp source target",
    "sed -i 's/old/new/' file",
    "mkdir generated-dir",
    "touch generated.tmp",
    "gh repo create dotnix-test",
    "git fsck --lost-found",
    "git fsck \"--lost-found\"",
    "git fsck \"$FSCK_MODE\"",
    "gh repo clone owner/repo",
)
SAFE_READ_INPUTS = (
    "git status --short",
    "git --no-pager status --short",
    "git -C /tmp/dotnix-repo status --short",
    "git -c core.fsmonitor=true status --short",
    "git branch --show-current",
    "git branch --list",
    "git branch -vv",
    "command -v git",
    "git config --get gc.auto",
    "git config --get remote.$MODE",
    "git log --grep='remote prune'",
    "git --git-dir=.git status --short",
    "git --git-dir .git config --get gc.auto",
    "git --work-tree=. log --grep='remote prune'",
    "git config --get remote.prune",
    "git show refs/remotes/origin/prune",
    "git diff remote-prune",
    "git rev-parse refs/remotes/origin/prune",
    "git log --grep='--output'",
    "git --work-tree=. log --grep='-o'",
    "git log --grep='--output=/tmp'",
    "git --work-tree=. log --grep='--output'",
)
BUILD_ASK_INPUTS = ("git fetch --no-prune origin",)
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
            for deny_pattern in (
                "*;*",
                "*&*",
                "*|*",
                "*>*",
                "*<*",
                "*$(*",
                "*`*",
                "*\n*",
            ):
                with self.subTest(pattern=ask_pattern, deny=deny_pattern):
                    self.assertLess(
                        permission_keys.index(ask_pattern),
                        permission_keys.index(deny_pattern),
                    )

    def test_out_of_authority_local_delete_resolves_deny(self) -> None:
        for surface_id in SURFACE_IDS:
            surface = self.surfaces()[surface_id]
            base_permission, agent_permission = self.source_permissions(surface)
            for input_value in OUT_OF_AUTHORITY_LOCAL_INPUTS:
                with self.subTest(surface=surface_id, input=input_value):
                    self.assertEqual(
                        _effective_action(
                            base_permission, agent_permission, "bash", input_value
                        ),
                        "deny",
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

    def test_git_prune_patterns_preserve_safe_reads_and_non_pruning_fetch(self) -> None:
        surface = self.surfaces()["build"]
        base_permission, agent_permission = self.source_permissions(surface)
        for input_value in SAFE_READ_INPUTS[-2:]:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "allow",
                )
        for input_value in BUILD_ASK_INPUTS:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "ask",
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
            "git -c core.fsmonitor=./evil status --short",
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

    def test_verifier_preserves_inherited_denies_and_local_delete_deny(self) -> None:
        surface = self.surfaces()["verifier"]
        _, agent_permission = self.source_permissions(surface)
        verifier_bash = agent_permission["bash"]
        self.assertNotIn("*", verifier_bash)
        self.assertEqual(verifier_bash["rm*"], "deny")

        base_permission, agent_permission = self.source_permissions(surface)
        for input_value in VERIFIER_INHERITED_DENY_INPUTS:
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "deny",
                )
        for input_value in (*SAFE_READ_INPUTS[1:4], *SAFE_READ_INPUTS[-3:]):
            with self.subTest(input=input_value):
                self.assertEqual(
                    _effective_action(
                        base_permission, agent_permission, "bash", input_value
                    ),
                    "allow",
                )
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
