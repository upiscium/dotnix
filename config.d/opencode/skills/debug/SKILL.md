---
name: debug
description: Use when a bug, runtime error, or failing test requires systematic reproduction, diagnosis, and repair.
---

# Debug

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Fix the observed symptom and expected behavior in precise terms.
2. Establish the smallest reliable reproduction.
3. Collect errors, traces, inputs, environment facts, and relevant recent history.
4. Enumerate plausible causes and identify evidence that would distinguish them.
5. Test one hypothesis at a time; label supported, rejected, and untested hypotheses.
6. Establish the root cause before editing. Delegate complex diagnosis to `investigator` when useful.
7. Implement the smallest root-cause fix.
8. Verify against the original reproduction and project-standard checks.
9. Add a regression test when it can reliably encode the failure.

After three failed repair attempts, stop repeating the approach and reassess assumptions, interfaces, and architecture. Finish with root cause confidence, evidence, changed files, verification, and remaining uncertainty. Do not claim a root cause that evidence does not establish.
