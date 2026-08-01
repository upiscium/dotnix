---
name: benchmark
description: Use when establishing or comparing reproducible performance measurements.
---

# Benchmark

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata including the default branch. Treat absent conventions as unknown; do not guess.

Confirm the measured target, comparison point, workload, and metric. This workflow never edits source files; use a separate implementation workflow for benchmark code or optimization changes. Stop if the workload, baseline, environment, or measurement method cannot be made comparable.

1. Establish a reproducible baseline and record revision, configuration, dependency versions, hardware, operating system, and environmental conditions.
2. Define inputs, dataset, command, timing scope, warmup, cache state, isolation, and sampling method before measuring.
3. Delegate benchmark execution to `verifier`, run multiple samples after warmup, and report central tendency, spread or variance, outliers, and measurement limitations. Disposable build artifacts and caches must remain within project-standard locations.
4. Compare before and after using the same workload and environment. Investigate materially different conditions rather than normalizing them silently.
5. Use `verifier` for relevant correctness checks as well as execution; do not infer performance from unsupported claims or a single noisy sample.

Return exact reproduction commands, raw or preserved measurements, environment, baseline and candidate results, comparison method, uncertainty, evidence, and unresolved confounders. Stop rather than claim improvement when evidence is insufficient.
