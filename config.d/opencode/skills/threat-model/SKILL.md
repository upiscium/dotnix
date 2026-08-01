---
name: threat-model
description: Use when a read-only threat model is needed for a system, feature, or change.
---

# Threat Model

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata including the default branch. Treat absent conventions as unknown; do not guess.

This workflow is read-only. Do not edit code, create issues, or post findings remotely. Confirm the system or change in scope and stop if its boundaries or required context cannot be established.

1. Describe scope, assumptions, assets, security properties, trust boundaries, actors, and attacker capabilities.
2. Trace relevant data flows, entry points, privileged operations, persistence, secrets, and external dependencies.
3. Derive concrete threats tied to assets and flows; distinguish evidence from assumptions and avoid generic speculation.
4. Record mitigations, verification evidence, gaps, residual risk, and recommended owners or follow-up.
5. Use `security-reviewer` only for concrete attack paths in an existing change. Use `architect` for prospective, consequential trust-boundary or systemic design decisions; keep system-level threat modeling in this workflow rather than forcing it into a diff-review role.

Stop when scope, evidence, or attacker assumptions are materially ambiguous. Return an evidence-based model with scope, assets, boundaries, capabilities, flows, threats, mitigations, residual risks, unanswered questions, and excluded areas.
