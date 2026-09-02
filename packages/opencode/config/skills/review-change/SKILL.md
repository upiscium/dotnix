---
name: review-change
description: Use when reviewing the current change, a commit range, or a pull request without modifying code by default.
---

# Review Change

This workflow is read-only unless explicitly given a mutating follow-up.

Agent-ready awareness:

- Detect repository Agent-ready mode if and only if both `.automation/VERSION` and `.automation/INIT.md` exist.
- If Agent-ready, load `AGENTS.md` and repository-local guidance from `.automation/INIT.md` (including any Agent Core directives) before proceeding.
- When present, use optional local Task State context for workflow continuity; never write Task State in this workflow.
- If not Agent-ready, treat it as generic and continue with global conventions only.
- Read-only workflow rule: do not mutate Task State.
- If local initialize is defined in `INIT.md` and context is appropriate, run it once before review analysis.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Confirm the requested review target and exact diff range. Never assume a branch name.
2. If the change is large, delegate file-classification and dependency tracing to `explore`.
3. Classify changed files and impacted boundaries.
4. Run `reviewer` on the relevant scope.
5. Record executable verification needed for the verdict as a residual gap; do not execute or delegate it from this read-only workflow.
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
