---
name: release
description: Use when preparing or publishing a repository release.
---

# Release

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown; do not guess release commands, version formats, or destructive operations.

1. Confirm the requested version, release scope, repository, and whether the user authorizes a Draft Release or publication. Stop if any consequential detail is ambiguous.
2. Detect the project’s release conventions, version sources, tag format, changelog process, artifact definitions, signing requirements, and CI release workflow from repository evidence and Git tags.
3. Inspect status, branch, relevant history, and existing tags without overwriting local work. Check that the version is consistent, the changelog is adequate, and expected artifacts can be reproduced.
4. Make only the minimal release-preparation changes. Run `verifier`; use `reviewer` for the release diff and `security-reviewer` when signing, credentials, generated artifacts, publishing, or another trust boundary is involved.
5. Report commands, results, artifact identities or checksums, tag/release status, and skipped checks. Never fabricate results or claim an artifact was uploaded when it was not.
6. A Draft Release may be created when requested and safe. Immediately before publication, tag push, or asset upload, re-check clean status, branch, immutable commit and tag identities, existing remote state, and artifact checksums, then require explicit user confirmation for that action.

Never merge automatically, force-push, expose credentials, overwrite an existing tag or release, or publish from an unsafe branch. Stop when conventions, version identity, artifacts, permissions, or verification are insufficient, and report the blocker and next required decision.
