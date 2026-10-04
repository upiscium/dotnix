#!/usr/bin/env bash
# Build-time backport of NixOS/nixpkgs#563241; never touches user runtime state.
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -f "$1" ] || [ -L "$1" ]; then
  echo "opencode splitting workaround: expected one regular build.ts file" >&2
  exit 1
fi

build_script="$1"
# Fail closed on upstream drift rather than claiming an unpatched build is fixed.
pattern='^[[:blank:]]*splitting: (true|false),[[:blank:]]*$'
count=$(grep -Ec "$pattern" "$build_script" || true)
if [ "$count" != 1 ]; then
  echo "opencode splitting workaround: expected exactly one splitting property; review upstream build.ts" >&2
  exit 1
fi

# Nixpkgs may already have applied the same workaround. In that case do not write.
if grep -Eq '^[[:blank:]]*splitting: true,[[:blank:]]*$' "$build_script"; then
  sed -i -E 's/^([[:blank:]]*)splitting: true,([[:blank:]]*)$/\1splitting: false,\2/' "$build_script"
fi
