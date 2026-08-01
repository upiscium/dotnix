---
name: worktree-task
description: Use when performing a task in an isolated Git worktree.
---

# Worktree Task

Before acting, discover applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and build entry points (including `Justfile`, `Makefile`, `flake.nix`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakeLists.txt`, `go.mod`, `Gemfile`, Maven or Gradle files, and `composer.json` when present), CI workflow files, existing tests, and Git metadata for the default branch. Treat absent conventions as unknown; do not guess branch names, paths, cleanup, or project commands.

1. Confirm the task, intended branch, and requested worktree location. Inspect repository status, current and detected default branches, remotes, and all existing worktrees.
2. Choose a non-conflicting branch and path based on repository evidence. Check branch names, paths, worktree registrations, uncommitted changes, and relevant refs before creation; never overwrite an existing path or local work.
3. Stop and ask when the path, branch, base, or ownership is ambiguous, or when uncommitted changes or an existing checkout could be affected. Create the isolated worktree only after these checks pass and only when its path is within the active workspace boundary. For an external path, report the exact creation and restart commands for the user to run; do not bypass `external_directory` restrictions.
4. Hand work off to a session whose active workspace is the new worktree; do not bypass the original session's external-directory boundary. Run all task work and verification there. Discover and follow its applicable guidance, keep changes limited to the requested scope, and do not stage unrelated files.
5. Report the worktree path, branch, base, handoff command or session, changed files, commands, verification evidence, and unresolved risks. Use `verifier`, `reviewer`, and `security-reviewer` only when the task’s scope warrants them.

Do not switch or reset the original worktree, overwrite paths or branches, force-push, merge automatically, or clean up the worktree automatically. Deleting a worktree or branch requires explicit user confirmation; preserve it and report the exact cleanup command when confirmation is absent.
