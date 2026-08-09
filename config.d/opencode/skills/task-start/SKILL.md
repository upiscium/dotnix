---
name: task-start
description: Start a scoped workflow by creating a dedicated task worktree.
---

# Task Start

Use only when asked to launch a dedicated, isolated worktree for one workflow.

1. Confirm the requested workflow and target branch/reference from `$ARGUMENTS`.
2. Inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and Git guidance, CI workflows, and repository state (status, remotes, branches, existing worktrees).
3. Confirm a non-conflicting branch/path and create or reuse a safe worktree only when checks are unambiguous.
4. Do not alter the original worktree or branch; do not delete or clean anything unless explicitly approved.
5. Hand off to the created worktree: report branch, path, base, and the exact next command (`/task-run <workflow> ...`) for the user/session.
6. For external-worktree locations, provide the exact creation and handoff command sequence for user execution and do not bypass `external_directory` restrictions.

Keep only the requested scope active and report unresolved risks before proceeding.
