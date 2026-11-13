#!/usr/bin/env bash
# Synthetic, disposable regression for the Claude input configuration merger.
set -euo pipefail

script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common/home/claude/apply-preferences.sh"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p -- "$fixture/company" "$fixture/personal"
cat > "$fixture/personal/settings.json" <<'JSON'
{"editorMode":"normal","permissions":{"allow":["Bash(git status)"]},"theme":"dark"}
JSON
cat > "$fixture/personal/keybindings.json" <<'JSON'
{"bindings":[{"context":"Chat","bindings":{"ctrl+e":"chat:externalEditor","enter":"chat:submit"}},{"context":"Global","bindings":{"ctrl+t":"app:toggleTodos"}}]}
JSON

bash "$script" "$(command -v jq)" "$fixture/company" "$fixture/personal"
for profile in company personal; do
  jq -e '.editorMode == "vim"' "$fixture/$profile/settings.json" >/dev/null
  jq -e '[.bindings[] | select(.context == "Chat") | .bindings | select(.enter == "chat:newline" and .["ctrl+enter"] == "chat:submit")] | length == 1' "$fixture/$profile/keybindings.json" >/dev/null
done
jq -e '.permissions.allow == ["Bash(git status)"] and .theme == "dark"' "$fixture/personal/settings.json" >/dev/null
jq -e '.bindings | length == 2' "$fixture/personal/keybindings.json" >/dev/null
jq -e '.bindings[0].bindings["ctrl+e"] == "chat:externalEditor" and .bindings[1].bindings["ctrl+t"] == "app:toggleTodos"' "$fixture/personal/keybindings.json" >/dev/null

before="$(sha256sum "$fixture/company/settings.json" "$fixture/company/keybindings.json" "$fixture/personal/settings.json" "$fixture/personal/keybindings.json")"
bash "$script" "$(command -v jq)" "$fixture/company" "$fixture/personal"
after="$(sha256sum "$fixture/company/settings.json" "$fixture/company/keybindings.json" "$fixture/personal/settings.json" "$fixture/personal/keybindings.json")"
[[ "$before" == "$after" ]]

printf '{broken JSON' > "$fixture/personal/settings.json"
if bash "$script" "$(command -v jq)" "$fixture/personal" >/dev/null 2>&1; then
  echo 'Invalid JSON must fail closed' >&2
  exit 1
fi
[[ "$(cat "$fixture/personal/settings.json")" == '{broken JSON' ]]

echo 'Claude input preferences: PASS'
