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
