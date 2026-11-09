#!/usr/bin/env bash
# Merge CLI input preferences into both Claude account profiles without replacing
# existing authentication, permissions, plugins, or other user-owned settings.
set -euo pipefail

if (( $# < 2 )); then
  echo "usage: $0 <jq-executable> <config-dir> [<config-dir> ...]" >&2
  exit 2
fi
jq_bin="$1"
shift

merge_json() {
  local path="$1" filter="$2" tmp
  if [[ -L "$path" || ( -e "$path" && ! -f "$path" ) ]]; then
    echo "Refusing non-regular Claude configuration: $path" >&2
    return 1
  fi

  tmp="$(mktemp "${path}.tmp.XXXXXX")"
  if [[ -f "$path" ]]; then
    if ! "$jq_bin" -e "$filter" "$path" > "$tmp"; then
      rm -f -- "$tmp"
      return 1
    fi
  else
    if ! printf '{}\n' | "$jq_bin" -e "$filter" > "$tmp"; then
      rm -f -- "$tmp"
      return 1
    fi
  fi

  chmod 600 "$tmp"
  if [[ -f "$path" ]] && cmp -s -- "$path" "$tmp"; then
    rm -f -- "$tmp"
  else
    mv -f -- "$tmp" "$path"
  fi
}

for config_dir in "$@"; do
  if [[ -L "$config_dir" || ( -e "$config_dir" && ! -d "$config_dir" ) ]]; then
    echo "Refusing non-directory Claude config root: $config_dir" >&2
    exit 1
  fi
  mkdir -p -- "$config_dir"

  merge_json "$config_dir/settings.json" '
    if type == "object" then .editorMode = "vim"
    else error("settings.json must contain a JSON object") end
  '
  merge_json "$config_dir/keybindings.json" '
    if type != "object" then
      error("keybindings.json must contain a JSON object")
    else
      .["$schema"] //= "https://www.schemastore.org/claude-code-keybindings.json"
      | .["$docs"] //= "https://code.claude.com/docs/en/keybindings"
      | .bindings = (
          (.bindings // [])
          | if type == "array" then . else error("bindings must be an array") end
          | if any(.[]; .context? == "Chat") then
              map(
                if .context? == "Chat" then
                  .bindings = ((.bindings // {}) + {
                    "enter": "chat:newline",
                    "ctrl+enter": "chat:submit"
                  })
                else . end
              )
            else
              . + [{
                "context": "Chat",
                "bindings": {
                  "enter": "chat:newline",
                  "ctrl+enter": "chat:submit"
                }
              }]
            end
        )
    end
  '
done
