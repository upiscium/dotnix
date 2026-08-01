---
name: publish-pr
description: Use only when the user asks to commit current local changes, push them, and create a Draft pull request.
---

# Publish PR

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Confirm repository contribution guidance and the detected default branch.
2. Inspect the current branch, status, full diff, remote tracking, and recent commit style.
3. Refuse direct publication from the default branch; create or request an appropriate topic branch without overwriting local work.
4. State exactly which files belong in the commit. Exclude unrelated and unreviewed changes; never stage everything blindly.
5. Confirm real verification results and disclose skipped or failed checks.
6. Check the staged diff for secrets and unintended content.
7. Create a concise repository-appropriate commit, then push without force.
8. Create a Draft PR against the detected base branch.
9. Include summary, verification evidence, risks, and related issues in the PR body.

Never fabricate verification, expose secrets, force-push, push directly to the default branch, or merge. Stop for user confirmation when permissions request commit or push approval, or when commit scope is ambiguous.
