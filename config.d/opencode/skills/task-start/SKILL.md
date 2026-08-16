---
name: task-start
description: Start a scoped workflow by creating a dedicated task worktree.
---

# Task Start

Use only when asked to launch a dedicated, isolated worktree for one workflow.

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed: Agent-ready path or Generic path.

Agent-ready path:

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional task state.
2. Load the repository-local `initialize` skill when available.
3. Discover local task lifecycle conventions and available task orchestration entry points.
4. Use the repository-local Task lifecycle for explicit task creation/attachment.
5. If local policy requires specific Task Identity, branch, or worktree ownership, follow it and stop here.
6. If local guidance is absent for required steps, ask the user to run the repository-local workflow and stop.

Generic path:

1. Confirm the requested workflow and target branch/reference from `$ARGUMENTS`.
2. Inspect applicable `AGENTS.md`, `README*`, `CONTRIBUTING*`, tracked manifests and Git guidance, CI workflows, and repository state (status, remotes, branches, existing worktrees).
3. Confirm a non-conflicting branch/path and create or reuse a safe worktree only when checks are unambiguous.
4. Do not alter the original worktree or branch; do not delete or clean anything unless explicitly approved.
5. Hand off to the created worktree: report branch, path, base, and the exact next command (`/task-run <workflow> ...`) for the user/session.
6. For external-worktree locations, provide the exact creation and handoff command sequence for user execution and do not bypass `external_directory` restrictions.

Keep only the requested scope active and report unresolved risks before proceeding.
