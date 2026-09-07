#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)

cd -- "$repo_root"

echo "==> Testing OpenCodePolicy updater lock contract"
python_args=(
  -m unittest discover
  -s tests
  -p 'test_opencode_policy_lock_update.py'
  -v
)
if command -v python3 >/dev/null 2>&1; then
  python3 "${python_args[@]}"
else
  nix develop --no-update-lock-file --command \
    python3 "${python_args[@]}"
fi

echo "==> Testing package registry contract"
tests/package-registry/test.sh

echo "==> Evaluating all supported systems"
nix flake check \
  --all-systems \
  --no-build \
  --no-update-lock-file
