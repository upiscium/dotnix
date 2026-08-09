---
name: task-run
description: Execute a scoped workflow inside a dedicated task worktree.
---

# Task Run

Do not start or run worktree setup here. This workflow is valid only inside a dedicated task worktree returned by `/task-start`.

1. Verify you are running inside the dedicated worktree that was explicitly created for this task; if not provable, stop and ask for `/task-start <task>` before continuing.
2. Identify the requested workflow from `$ARGUMENTS` (for example: `implement-issue`, `debug`, `fix-ci`, or `review-change`).
3. Load the corresponding workflow skill and follow it.
4. Keep the work strictly to the requested task scope and avoid unrelated cleanup or branch changes in this workspace.
5. Report changed files, verification, unresolved items, and explicit handoff risks.
