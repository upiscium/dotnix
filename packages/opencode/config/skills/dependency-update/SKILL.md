---
name: dependency-update
description: Use when updating a user-selected dependency or dependency scope.
---

# Dependency Update

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed: Agent-ready path or Generic path.

Agent-ready setup (skip in Generic mode):

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional task state.
2. Load the repository-local `initialize` skill when available.
3. If local policy requires, enter Task lifecycle (`task-start`/`task-run`) before any state-write or publication step.
4. Preserve normal dependency mutation through repository tools (edits to manifests/lockfiles) in the core workflow; do not route ordinary source edits through guarded APIs.

Then follow this core workflow in either mode. Discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown; do not guess package managers, update commands, or version policy.

1. Require an explicit dependency and scope (including an allowed version range or target when relevant). Use this workflow only for compatible or version-only updates; route breaking API, data, platform, or compatibility transitions to `migrate`. If none is supplied, or the request implies an unrelated bulk upgrade, ask and stop.
2. Discover the package manager, manifest and lockfile, workspace boundaries, update policy, relevant CI checks, and current dependency graph from repository evidence.
3. Have `scout` inspect selected dependency changelogs, release notes, compatibility guidance, and advisories. Record source URLs, versions, and uncertainty; do not infer unavailable facts.
4. Inspect status and diff, then make the smallest compatible update only for selected scope, including the authoritative lockfile when the package manager uses one. Do not rewrite unrelated lockfile entries without evidence that resolution requires it.
5. Run `verifier` on relevant tests, lint, type, build, and audit checks; use `reviewer` for the resulting diff and `security-reviewer` for security-sensitive dependencies, advisories, execution, or trust-boundary changes.
6. Report changed manifests and lockfiles, dependency graph effects, upstream evidence, exact verification results, skipped checks, and remaining risks. Never claim checks or advisory conclusions that were not established.

Stop before editing when the dependency, scope, package manager, compatibility, or safe update path is unclear. Never weaken constraints, suppress advisories, remove tests, expose credentials, force-push, merge automatically, or include unrelated upgrades.
