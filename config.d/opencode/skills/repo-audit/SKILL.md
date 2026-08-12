---
name: repo-audit
description: Use when auditing an entire repository for actionable correctness, security, quality, CI, and maintenance improvements.
---

# Repository Audit

This workflow is read-only. Do not change code or create issues without a separate explicit request.

Agent-ready awareness:

- Detect repository Agent-ready mode if and only if both `.automation/VERSION` and `.automation/INIT.md` exist.
- If Agent-ready, load `AGENTS.md` and repository-local guidance from `.automation/INIT.md` (including any Agent Core directives) before analysis.
- When present, use optional local Task State context for workflow continuity; never write Task State in this workflow.
- If not Agent-ready, treat it as generic and continue with global conventions only.
- Read-only workflow rule: do not mutate Task State.
- If local initialize is defined in `INIT.md` and context is appropriate, run it before audit actions.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

1. Establish repository purpose, release configuration, and the applicable discovered conventions.
2. Define and report sampled and excluded areas before drawing conclusions.
3. Inspect bugs, unhandled errors, security boundaries, test gaps, design inconsistencies, dead code, obsolete compatibility paths, CI, documentation drift, dependencies, builds, distribution, and developer experience.
4. Use `reviewer` for deep analysis of material candidates, `security-reviewer` for concrete trust-boundary risks, and `architect` only for consequential systemic concerns.
5. Validate each candidate against surrounding code and existing tests. Exclude unsupported speculation.

For each retained candidate report priority, confidence, evidence, impact scope, recommended response, and an issue-sized unit of work. If no candidate remains, state the audited scope and residual gaps.
