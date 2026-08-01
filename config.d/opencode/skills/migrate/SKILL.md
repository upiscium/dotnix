---
name: migrate
description: Use when a breaking API, data, platform, system, or compatibility transition must be migrated to a specified target.
---

# Migrate

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata including the default branch. Treat absent conventions as unknown; do not guess.

Require an explicit target, source, scope, and acceptable compatibility window. If the target or required context is missing, stop and ask. Use `scout` to research target breaking changes and record authoritative evidence; do not assume compatibility.

1. Inventory callers, interfaces, dependencies, configuration, data formats, persistence, deployment paths, observability, and rollback constraints.
2. Define compatibility behavior, migration stages, validation gates, rollback plan, ownership, and stop conditions.
3. Use `architect` for consequential cross-system, lifecycle, persistence, or trust-boundary design decisions.
4. Implement repository changes in small staged steps, preserving a reversible path and validating each stage against discovered project checks. Keep live apply or cutover as a separate phase; do not mutate external or persistent state by default.
5. Use `verifier` for migration and regression checks, `reviewer` for the resulting change, and `security-reviewer` when secrets, permissions, execution, persistence, or trust boundaries are affected.
6. Before any live apply or cutover, require an explicit environment identity, tested backup and restore evidence, rollback gates, current-state revalidation, and just-in-time user confirmation for every external-state mutation. Do not perform destructive data changes, irreversible cutovers, deletion, or irreversible dependency transitions without explicit confirmation and a validated recovery plan.

Stop for unknown breaking changes, incomplete inventory, failed validation, unsafe rollback, or ambiguous destructive action. Return target and assumptions, inventory, researched evidence, staged changes, compatibility and rollback results, verification commands and evidence, unresolved risks, and any required confirmation.
