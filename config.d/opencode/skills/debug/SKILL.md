---
name: debug
description: Use when a bug, runtime error, or failing test requires systematic reproduction, diagnosis, and repair.
---

# Debug

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Fix the observed symptom in precise terms.
2. Establish the smallest reliable reproduction.
3. Collect errors, traces, inputs, environment facts, and relevant history.
4. Enumerate plausible causes and evidence required to distinguish them.
5. If the root cause is not clear, delegate to `investigator`.
6. Validate the root cause before editing. Delegate limited fixes to `general` only after confirmation.
7. Execute reproduction and project-standard checks through `verifier`.
8. Add a regression test when it can reliably encode the failure.
9. Stop after three failed attempts and revisit assumptions, interface contracts, or architecture.

Finish with root-cause confidence, evidence, changed files, verification, and remaining uncertainty. Do not claim a root cause that evidence does not establish.
