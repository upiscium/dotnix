---
name: backport
description: Use when explicitly backporting specified commits to a specified target branch.
---

# Backport

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata including the default branch. Treat absent conventions as unknown; do not guess.

Require explicit source commit(s) and target branch. If either is missing, stop and ask. Confirm the commits, target ancestry, repository state, and a safe dedicated branch or worktree. Do not switch branches over local changes or overwrite unrelated work.

1. Inspect the requested commits and target branch, including relevant release and compatibility context.
2. Create or confirm an isolated branch/worktree only after safety checks; do not alter the target branch directly.
3. Cherry-pick only the explicitly requested commits, preserving authorship and stopping on any conflict.
4. Do not guess conflict resolutions. Report the conflict and wait for explicit direction when intent is ambiguous.
5. Run `verifier` using discovered project checks, then resolve failures and re-run applicable checks.
6. Before any push, re-check the dedicated branch, target, resulting immutable commit identities, status, remote state, and verification, and require an explicit user request. Optionally create a Draft PR only when requested and verification is adequate; never merge automatically.

Stop for missing inputs, unsafe worktree state, ambiguous conflicts, unavailable history, or inadequate verification. Report source commits, target, resulting commit(s), changed files, commands and evidence, unresolved conflicts or risks, and whether a Draft PR was created.
