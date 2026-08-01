---
name: fix-ci
description: Use when diagnosing and minimally fixing failed CI checks for a specified branch or pull request.
---

# Fix CI

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Identify the target branch or PR and the repository's CI provider from checked-in configuration and remote metadata.
2. Confirm local verification entry points.
3. Locate failed checks and jobs, then obtain the relevant logs.
4. Delegate reproduction and root-cause analysis to `investigator`.
5. Reproduce locally when safe and feasible.
6. Implement the smallest root-cause fix. Never disable CI, delete a valid test, or suppress a failure to make a check green.
7. Run relevant local verification through `verifier`.
8. Re-run remote CI only when needed and explicitly permitted.
9. Report the failed check, root cause and confidence, changed files, local evidence, remote status, and remaining uncertainty.

Stop without a speculative edit when logs or evidence cannot establish a responsible fix.
