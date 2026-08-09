---
name: fix-ci
description: Use when diagnosing and minimally fixing failed CI checks for a specified branch or pull request.
---

# Fix CI

This workflow requires a dedicated task worktree. If the session is not a `/task-start` worktree, ask for `/task-start fix-ci <context>` and stop.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Identify the target branch or PR and CI context from checked-in config and remote metadata.
2. Confirm local verification commands.
3. Locate failed jobs and fetch logs.
4. Delegate investigation to `investigator`.
5. Reproduce locally when safe and feasible.
6. Implement the smallest root-cause fix.
7. Verify the fix with `verifier`.
8. Re-run relevant checks only when explicitly permitted.

Stop without speculative edits when evidence is insufficient to establish a responsible fix.
