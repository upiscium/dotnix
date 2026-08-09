---
name: review-change
description: Use when reviewing the current change, a commit range, or a pull request without modifying code by default.
---

# Review Change

This workflow requires a dedicated task worktree. If the session is not a `/task-start` worktree, ask for `/task-start review-change <scope>` and stop.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Confirm the requested review target and exact diff range. Never assume a branch name.
2. If the change is large, delegate file-classification and dependency tracing to `explore`.
3. Classify changed files and impacted boundaries.
4. Run `reviewer` on the relevant scope.
5. Run `verifier` when executable evidence materially affects the verdict.
6. Run `architect` for cross-module, public API, lifecycle, persistence, or security-boundary changes.
7. Run `security-reviewer` only when trust boundaries are affected.
8. Merge findings, remove duplicates, and separate confirmed findings from uncertainties.

Return:

## Review summary

### Blocking
### Important
### Minor
### Verification
### Dismissed or duplicate findings
### Verdict

Every retained finding must include severity, confidence, location, trigger, impact, evidence, and a concise response. If there are no findings, state the reviewed scope and residual verification gaps.
