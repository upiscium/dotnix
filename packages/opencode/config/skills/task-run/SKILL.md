---
name: task-run
description: Execute a scoped workflow
---

# Task Run

At workflow start, detect Agent-ready mode:

- Agent-ready when **both** `.automation/VERSION` and `.automation/INIT.md` exist.
- Exactly one path must be followed: Agent-ready path or Generic path.

Agent-ready path:

1. Read `AGENTS.md`, `.automation/INIT.md`, and optional task state.
2. Load the repository-local `initialize` skill when available.
3. Run within an explicit local task/worktree context as defined by local policy.
4. Execute local workflow and guarded APIs for Task State, worktree lifecycle, and publication/integration writes.

Generic path:

1. Do not run worktree setup here.
2. Treat the first argument as an explicit workflow name (for example: `implement-issue`, `debug`, `fix-ci`, or `review-change`) and the remaining arguments as that workflow's scope. Do not interpret it as a Templates Task ID.
3. Load the corresponding workflow skill and execute it in the current repository context, honoring the current branch/status scope.
4. Keep the work strictly to the requested task scope and avoid unrelated cleanup or branch changes.
5. If a dedicated worktree is explicitly requested or required by local policy, hand off to `/task-start` and continue in that context.
6. Report changed files, verification, unresolved items, and explicit handoff risks.

In an Agent-ready repository, the repository-local `/task-run <TASK-ID>` command and skill override this global generic contract.
