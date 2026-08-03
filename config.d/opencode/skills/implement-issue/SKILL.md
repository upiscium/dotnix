---
name: implement-issue
description: Use only when the user identifies a GitHub Issue to implement through a Draft pull request.
---

# Implement Issue

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

Never select an issue. If no issue number or URL is supplied, ask for one and stop. Never merge automatically.

1. Fetch the specified issue and repository metadata.
2. Confirm the discovered project conventions and acceptance criteria.
3. If needed, delegate to `explore` first for impact analysis and test-location discovery.
4. Split implementation into 2 to 4 independent, non-overlapping scopes and delegate each to `general`.
5. For each workstream, provide exact files, completion criteria, and prohibited changes. Never assign the same file concurrently, and sequence dependent work.
6. Parent owns architecture, task decomposition, conflict resolution, and final integration decisions.
7. Inspect and integrate every worker diff; do not rely on summaries as sufficient evidence.
8. Execute `verifier` and include results.
9. Use `reviewer` when independent correctness review is warranted.
10. Resolve failures and re-verify.
11. Include unresolved items when verification is incomplete.

Issue auto-selection remains forbidden, Draft PR issuance remains explicit, branch and repository safety checks remain in force, and shared files/dependent tasks must run sequentially.
