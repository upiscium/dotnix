---
name: implement-issue
description: Use only when the user identifies a GitHub Issue to implement through a Draft pull request.
---

# Implement Issue

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

Never select an issue. If no issue number or URL is supplied, ask for one and stop. Never merge automatically.

1. Fetch the specified issue and repository metadata.
2. Confirm the discovered project conventions relevant to the issue.
3. Extract acceptance criteria and identify missing information. Ask before making consequential assumptions.
4. Inspect the current branch and worktree. Do not overwrite or stage unrelated changes.
5. Create a dedicated branch only after confirming it is safe; never branch-switch over conflicting local work.
6. Split implementation into independent workstreams. Delegate two to four non-overlapping workstreams to `general` in parallel when useful.
7. Give each worker exact files, completion criteria, and prohibited changes. Never assign the same file concurrently, and sequence dependent work.
8. Inspect and integrate every worker diff. The parent owns design and integration decisions.
9. Run `verifier`. Use `reviewer`, and use `security-reviewer` only when trust boundaries are affected.
10. Resolve failures and re-verify. Do not claim checks that were not run.
11. Create a Draft pull request only after verification is adequate. Include evidence and unresolved risks.

Independent tests, documentation, and modules may run in parallel. Shared files and dependent tasks may not. Stop before the Draft PR if requirements, branch safety, permissions, or verification are inadequate, and report the blocker.
