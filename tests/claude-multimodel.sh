#!/usr/bin/env bash
# Synthetic, disposable regression for the multi-model Claude config installer.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$root/common/home/claude/apply-multimodel.sh"
src="$root/common/home/claude/multimodel"
fx="$(mktemp -d)"; trap 'rm -rf -- "$fx"' EXIT
mkdir -p "$fx/c/agents"
echo '{"editorMode":"vim","env":{"FOO":"1"},"permissions":{"allow":["Bash(ls)"]}}' > "$fx/c/settings.json"
printf '# mine\n\nkeep me\n' > "$fx/c/CLAUDE.md"
echo mine > "$fx/c/agents/user-own.md"

bash "$script" "$(command -v jq)" "$fx/c" "$src"
jq -e '.editorMode=="vim" and .env.FOO=="1" and .permissions.allow==["Bash(ls)"]
  and .env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=="2" and .env.CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS=="4"
  and (.env|has("CLAUDE_CODE_SUBAGENT_MODEL_FORCE")|not)' "$fx/c/settings.json" >/dev/null
grep -q 'keep me' "$fx/c/CLAUDE.md"
[[ "$(grep -c 'multimodel:begin' "$fx/c/CLAUDE.md")" == 1 ]]
[[ "$(cat "$fx/c/agents/user-own.md")" == mine ]]
for a in issue-implementer implementation-helper repository-researcher code-reviewer architecture-reviewer; do
  [[ -f "$fx/c/agents/$a.md" ]]; done
[[ -x "$fx/c/hooks/readonly-git.sh" && -f "$fx/c/skills/design-to-issues/SKILL.md" && -f "$fx/c/skills/implement-issue/SKILL.md" ]]

before="$(sha256sum "$fx"/c/settings.json "$fx"/c/CLAUDE.md)"
bash "$script" "$(command -v jq)" "$fx/c" "$src"
[[ "$before" == "$(sha256sum "$fx"/c/settings.json "$fx"/c/CLAUDE.md)" ]]

# read-only git hook
h="$fx/c/hooks/readonly-git.sh"
chk() { printf '{"tool_input":{"command":%s}}' "$(jq -Rn --arg c "$1" '$c')" | bash "$h" >/dev/null 2>&1; }
chk 'git diff main...HEAD'; chk 'git log --oneline -5'
! chk 'git diff > x'; ! chk 'git status; rm -rf /'; ! chk 'rm -rf x'; ! chk 'git diff --output=x'; ! chk 'git commit -m a'
echo 'Claude multimodel config: PASS'
