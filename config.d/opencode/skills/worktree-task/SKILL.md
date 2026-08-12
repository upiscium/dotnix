---
name: worktree-task
description: Use when performing a task in an isolated Git worktree.
---

# Worktree Task

Use this skill as a compatibility wrapper for `/worktree`.

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed: Agent-ready path or Generic path.

In Agent-ready repos:

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional local task state.
2. Load the repository-local `initialize` skill when available.
3. Do **not** run raw `git worktree` commands.
4. Use local Task lifecycle orchestration for worktree ownership and `.worktrees/`/.task-state ownership.
5. Hand workflow through local `task-start`/orchestrator and stop.

Generic path:

1. Confirm the task, intended branch, and requested worktree location. Inspect repository status, current and detected default branches, remotes, and all existing worktrees.
2. Choose a non-conflicting branch and path based on repository evidence. Check branch names, path ownership, worktree registrations, uncommitted changes, and refs before creation; never overwrite an existing path or local work.
3. Stop and ask when the path, branch, base, or ownership is ambiguous, or when local work could be affected. Create the worktree only after these checks pass and only when its path is within the active workspace boundary. For an external path, report the exact creation/restart commands for the user to run; do not bypass `external_directory` restrictions.
4. Hand work off to `/task-run` in the session whose active workspace is the new worktree; do not bypass the original session's external-directory boundary. Run task execution there.
5. Report the worktree path, branch, base, handoff command, commands, verification evidence, and unresolved risks. Use `verifier`, `reviewer`, and `security-reviewer` only when the task’s scope warrants them.

Do not switch or reset the original worktree, overwrite paths or branches, force-push, merge automatically, or clean up the worktree automatically. Deleting a worktree or branch requires explicit user confirmation; preserve it and report the exact cleanup command when confirmation is absent.
