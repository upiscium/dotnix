# Multi-model Claude Code setup

Source of truth for ~/.claude agents/skills/hooks, `.env` limits and the CLAUDE.md block
(installed by `apply-multimodel.sh`, wired in `module/home/claude.nix`, personal profile only).

## Sessions (recommended: two separate sessions)
- Design (Opus):         `cd <repo> && claude --model claude-opus-5-5 --remote-control "design-<repo>"` then `/design-to-issues <要求>`
- Implementation (Sonnet): `cd <repo> && claude --model claude-sonnet-5-5 --remote-control "impl-<repo>"` then `/implement-issue <番号>`
- Single-session (not recommended, Opus tokens): in an Opus session run `/implement-issue <番号>`; it delegates to `issue-implementer` (Sonnet).
- The systemd `claude remote-control --spawn` servers have no per-session model flag in v2.1.293
  (`--settings` needs >= 2.1.321); pick the model from the connected device (/model) per session.

## Limits
`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2`, `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS=4` via settings.json `.env`.
`CLAUDE_CODE_SUBAGENT_MODEL(_FORCE)` must stay unset.

## Cloud (Claude Code on the web)
~/.claude/{agents,skills,CLAUDE.md,settings.json} are NOT carried over; commit `.claude/agents` and `.claude/skills` into the repo to use them there.

## Local LLM delegation (Phase 1, processing only)
`agents/local-delegate.md` (Haiku) is the Claude-side dispatch window to the
Opencode local workers on TSUMGI. It is installed by the same agents glob in
`apply-multimodel.sh`; no script change is needed. Dispatch is explicit only
(the parent decides), never automatic, and the workers stay read-only and
advisory: the parent verifies file:line evidence before using any result.

| Worker | Model | Use for |
| --- | --- | --- |
| `local-investigator` | `tsumgi/qwen3.8-27b` | multi-file investigation, Japanese summarization/classification/extraction |
| `local-tracer` | `tsumgi/qwen3.8-flash-next-coder` | simple read/grep traces, code explanation, log/stack-trace analysis |
| `local-background` | `tsumgi/qwen3.6-35b-a3b-short` | low-priority background evidence, overflow only |

Authority: worker definitions, the retry rule (same agent/model, at most once,
only after a normal response with zero required tool calls) and metrics live
in the Opencode layer — `packages/opencode/config/local-workers.toml`,
`packages/opencode/config/agents/local-*.md` and the `local-workers` skill.
This layer does not redefine them. If a TSUMGI model ID changes there, update
the table above and `agents/local-delegate.md` in the same change window.
Judgment tasks (design, review verdicts, security, ambiguous requirements)
are never delegated.
