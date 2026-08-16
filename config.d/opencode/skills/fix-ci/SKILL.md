---
name: fix-ci
description: Use when diagnosing and minimally fixing failed CI checks for a specified branch or pull request.
---

# Fix CI

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed: Agent-ready path or Generic path.

Agent-ready setup (skip in Generic mode):

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional task state.
2. Load the repository-local `initialize` skill when available.
3. Perform diagnosis in the current workflow context first (no Task lifecycle needed for read-only analysis).
4. If diagnosis requires edits or branch state changes, enter local Task lifecycle (`task-start`/`task-run` path when required by local policy) before mutation.

Then follow this core workflow in either mode. Inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Identify the target branch or PR and CI context from checked-in config and remote metadata.
2. Confirm local verification commands.
3. Locate failed jobs and fetch logs.
4. Delegate investigation to `investigator`.
5. Reproduce locally when safe and feasible.
6. Implement the smallest root-cause fix.
7. Verify the fix with `verifier`.
8. Re-run relevant checks only when explicitly permitted.

Stop without speculative edits when evidence is insufficient to establish a responsible fix.
