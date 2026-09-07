#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

cat >"$tmp_dir/common.nix" <<'NIX'
let
  root = builtins.getEnv "REPO_ROOT";
  flake = builtins.getFlake ("path:" + root);
  lib = flake.inputs.nixpkgs.lib;
  cases = import (root + "/tests/package-registry/cases.nix") { inherit lib; };
  case = builtins.getAttr (builtins.getEnv "CASE_NAME") cases;
in
{
  expectedMessage = case.expectedMessage;
  expression = case.expression;
}
NIX

eval_case() {
  local output_mode=$1
  OUTPUT="$output_mode" nix eval --impure --no-update-lock-file --raw --expr "
    let value = import $tmp_dir/common.nix; in
    if builtins.getEnv \"OUTPUT\" == \"message\"
    then value.expectedMessage
    else if value.expression then \"true\" else \"false\"
  "
}

for case_name in valid invalid-name reserved-name systems-not-list systems-non-string systems-duplicate systems-unsupported default-non-function; do
  export REPO_ROOT="$repo_root" CASE_NAME="$case_name"
  if [ "$case_name" = valid ]; then
    output=$(eval_case expression)
    [ "$output" = true ]
  else
    expected=$(eval_case message)
    if stderr=$(eval_case expression 2>&1); then
      echo "FAIL: $case_name unexpectedly succeeded" >&2
      exit 1
    fi
    if [[ "$stderr" != *"$expected"* ]]; then
      echo "FAIL: $case_name error did not contain expected message: $expected" >&2
      printf '%s\n' "$stderr" >&2
      exit 1
    fi
  fi
  echo "PASS: $case_name"
done
