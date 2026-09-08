---
name: local-workers
description: Use ONLY for explicit manual or shadow dispatch to the disabled local-worker manifest with same-agent/same-model retry enforcement.
---

# Local workers

This is a Phase 1 manual/shadow workflow, disabled by default. Require an
explicit worker and one required tool (`read` or `grep`), then bind the bounded
objective to the manifest's exact agent/model. Use `local-investigator` for a
bounded multi-file investigation, `local-tracer` for a simple read/grep trace,
and `local-background` only for low-priority or overflow evidence gathering.
Do not choose a worker implicitly. Workers are read-only, advisory, and
non-authoritative; the parent remains responsible for all decisions.

Require a status-first response containing file/line/snippet, mechanism,
confidence, and unverified evidence. An exact model failure is `BLOCKED`.
Inspect the child transcript for the named required tool. Retry at most once,
and only after a normal successful response whose `required_tool_call_count`
is zero. The retry repeats the same bounded objective and required tool using
the same agent and same configured model, with `attempts = 2` and
`retry_reason = missing_required_tool_call`. API, runtime, model, permission,
schema, blocked, approval/decision, non-normal, or wrong-evidence failures are
not retry-eligible. After a second omission, return `BLOCKED`. There is no
fallback: never substitute a model or continue the bound objective with a
canonical role. OpenCode
v1.18.16's public API cannot enforce `toolChoice=required`, so this workflow
does not implement a plugin; required-tool and retry checks are parent/manual
controls.

Return a content-free session summary using the manifest's counters and
metadata. Record latency or token usage only when OpenCode reports it; never
estimate it, and never place prompts, file contents, or tool output in metrics.
