#!/usr/bin/env bash
# PreToolUse hook for the code-reviewer subagent: allow only read-only git
# commands through Bash. Exit 2 blocks the call and shows stderr to the model.
set -euo pipefail
cmd="$(jq -r '.tool_input.command // empty')"
if [[ "$cmd" =~ ^git[[:space:]]+(diff|log|show|status|blame|ls-files|rev-parse|merge-base)([[:space:]]|$) ]] \
   && ! [[ "$cmd" =~ [\;\&\|\<\>\`\$] || "$cmd" == *$'\n'* || "$cmd" == *--output* || "$cmd" == *--ext-diff* ]]; then
  exit 0
fi
echo "code-reviewer may only run read-only git commands (diff/log/show/status/blame/ls-files/rev-parse/merge-base) without shell operators." >&2
exit 2
