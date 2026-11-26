#!/usr/bin/env bash
# Install the multi-model (Opus plan / Sonnet implement / Haiku research) Claude
# Code setup into one config dir without replacing user-owned files:
#  - copies agents/skills/hooks that this repo manages (never deletes others)
#  - merges subagent limits into settings.json `.env` (other keys untouched)
#  - maintains a marked block in CLAUDE.md (content outside it is untouched)
set -euo pipefail

if (( $# != 3 )); then
  echo "usage: $0 <jq-executable> <config-dir> <multimodel-source-dir>" >&2
  exit 2
fi
jq_bin="$1" config_dir="$2" src="$3"
begin='<!-- multimodel:begin (managed by dotnix common/home/claude; edit there) -->'
end='<!-- multimodel:end -->'

for p in "$config_dir" "$config_dir/settings.json" "$config_dir/CLAUDE.md"; do
  if [[ -L "$p" ]]; then echo "Refusing symlink: $p" >&2; exit 1; fi
done
mkdir -p -- "$config_dir/agents" "$config_dir/hooks" "$config_dir/skills"

for f in "$src"/agents/*.md; do
  install -m 0644 -- "$f" "$config_dir/agents/$(basename "$f")"
done
for f in "$src"/hooks/*.sh; do
  install -m 0755 -- "$f" "$config_dir/hooks/$(basename "$f")"
done
for d in "$src"/skills/*/; do
  name="$(basename "$d")"
  mkdir -p -- "$config_dir/skills/$name"
  install -m 0644 -- "$d/SKILL.md" "$config_dir/skills/$name/SKILL.md"
done

# settings.json: .env only. Limits: nesting depth 2, concurrent subagents 4.
# CLAUDE_CODE_SUBAGENT_MODEL(_FORCE) is deliberately never set.
settings="$config_dir/settings.json"
tmp="$(mktemp "$settings.tmp.XXXXXX")"
[[ -f "$settings" ]] || printf '{}\n' > "$settings"
"$jq_bin" -e '
  if type != "object" then error("settings.json must contain a JSON object")
  else .env = ((.env // {}) + {
    "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2",
    "CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS": "4"
  }) end' "$settings" > "$tmp" || { rm -f -- "$tmp"; exit 1; }
chmod 600 "$tmp"
if cmp -s -- "$settings" "$tmp"; then rm -f -- "$tmp"; else mv -f -- "$tmp" "$settings"; fi

# CLAUDE.md: replace the marked block, or append it.
md="$config_dir/CLAUDE.md"
[[ -f "$md" ]] || : > "$md"
tmp="$(mktemp "$md.tmp.XXXXXX")"
awk -v b="$begin" '$0==b{skip=1} !skip{print} $0=="<!-- multimodel:end -->"{skip=0}' "$md" > "$tmp"
# trim trailing blank lines, then append the block
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp"
{ [[ -s "$tmp" ]] && printf '\n'; printf '%s\n' "$begin"; cat "$src/claude-md.md"; printf '%s\n' "$end"; } >> "$tmp"
if cmp -s -- "$md" "$tmp"; then rm -f -- "$tmp"; else chmod --reference="$md" "$tmp"; mv -f -- "$tmp" "$md"; fi
