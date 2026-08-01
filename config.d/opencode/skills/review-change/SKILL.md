---
name: review-change
description: Use when reviewing the current change, a commit range, or a pull request without modifying code by default.
---

# Review Change

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Confirm the requested review target. Never assume a branch name.
2. Determine the exact diff range and classify changed files and affected boundaries.
3. Run `reviewer` on the diff and relevant surrounding code.
4. Run `security-reviewer` only when authentication, authorization, secrets, execution, persistence, CI, deployment, or another trust boundary changes.
5. Run `architect` only for consequential cross-module, public API, persistence, lifecycle, agent configuration, or security-boundary changes.
6. Run `verifier` when executable evidence materially affects the verdict.
7. Validate findings against the diff, remove duplicates, and distinguish confirmed findings from uncertain ones.
8. Do not edit code, create issues, or post remote comments unless the user explicitly asks.

Return:

## Review summary

### Blocking
### Important
### Minor
### Verification
### Dismissed or duplicate findings
### Verdict

Every retained finding must include severity, confidence, location, trigger, impact, evidence, and a concise response. If there are no findings, state the reviewed scope and residual verification gaps.
