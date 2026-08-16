---
name: implement-issue
description: Use only when the user identifies a GitHub Issue to implement through a Draft pull request.
---

# Implement Issue

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed:
  - **if Agent-ready**: use Agent-ready path and stop there;
  - **else**: use Generic path.

Agent-ready path:

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional local task state.
2. Load the repository-local `initialize` skill when available.
3. Read the issue first from the explicit user input; ask if absent.
4. Derive the explicit stable Task ID/slug from local guidance using issue metadata.
5. Route through the repository-local task lifecycle using only discovered API:
   - invoke local `task-start` (or equivalent orchestrator), then
   - hand off to local `task-run`/`implement-issue` execution path.
6. Do not continue with build-time implementation in this skill. Stop after routing/launch.

Generic path:

1. Never select an issue. Require explicit issue URL/number or title+owner context and stop otherwise.
2. Fetch the specified issue and repository metadata.
3. Confirm the discovered project conventions and acceptance criteria.
4. If needed, delegate to `explore` first for impact analysis and test-location discovery.
5. Split implementation into 2 to 4 independent, non-overlapping scopes and delegate each to `general`.
6. For each workstream, provide exact files, completion criteria, and prohibited changes. Never assign the same file concurrently, and sequence dependent work.
7. Parent owns architecture, task decomposition, conflict resolution, and final integration decisions.
8. Inspect and integrate every worker diff; do not rely on summaries as sufficient evidence.
9. Execute `verifier` and include results.
10. Use `reviewer` when independent correctness review is warranted.
11. Resolve failures and re-verify.
12. Include unresolved items when verification is incomplete.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

Never select an issue. If no issue number or URL is supplied, ask for one and stop. Never merge automatically.

Issue auto-selection remains forbidden, Draft PR issuance remains explicit, branch and repository safety checks remain in force, and shared files/dependent tasks must run sequentially.
