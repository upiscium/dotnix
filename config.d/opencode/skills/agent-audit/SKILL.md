---
name: agent-audit
description: Use when auditing OpenCode agents, skills, commands, permissions, model allocation, and subagent boundaries.
---

# Agent Configuration Audit

This workflow is read-only unless the user separately requests fixes.

Agent-ready awareness:

- Detect repository Agent-ready mode if and only if both `.automation/VERSION` and `.automation/INIT.md` exist.
- If Agent-ready, load `AGENTS.md` and repository-local guidance from `.automation/INIT.md` (including any Agent Core directives) before analysis.
- When present, use optional local Task State context for workflow continuity; never write Task State in this workflow.
- If not Agent-ready, treat it as generic and continue with global conventions only.
- Read-only workflow rule: do not mutate Task State.
- If local initialize is defined in `INIT.md` and context is appropriate, run it before agent configuration checks.

Before acting, inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown and do not guess destructive operations.

Discover the installed OpenCode version and schema before evaluating configuration.

1. Inventory built-in overrides, custom agents, skills, commands, and their references.
2. Use `reviewer` to check responsibility overlap, duplication with built-ins, matching skill names and directories, selective descriptions, prompt length, least privilege, instruction-permission contradictions, model cost, destructive-operation guards, nonexistent tools, deprecated settings, command-skill duplication, project assumptions in global configuration, and subagent information boundaries.
3. Add `architect` only when the configuration or proposed change materially alters orchestration, privilege, or security boundaries.
4. Validate findings against the current published schema and installed CLI behavior. Separate confirmed incompatibilities from version-dependent uncertainty.

Return findings by severity with location, evidence, impact, and recommended response. Include checked agents, skills, commands, schema/version, and residual gaps. If no issue is found, explicitly report `No findings`.
