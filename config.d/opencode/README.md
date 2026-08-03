# OpenCode Global Configuration

This directory is deployed recursively to `~/.config/opencode/`. Changes apply to every repository using this Home Manager configuration.

## Configuration Layers

- **Agents** define persistent execution properties: role, model, edit and command permissions, subagent access, and required output boundaries.
- **Skills** define reusable workflows that an eligible agent loads when needed. They do not set models or permissions.
- **Commands** are short, user-initiated entry points. They select an agent and instruct it to load one skill rather than duplicating the workflow.

Built-in agents are overridden in `opencode.json`. Specialized custom agents, including `scout` because OpenCode 1.18.4 does not provide it as a built-in, live in `agents/`. Reusable workflows live in `skills/`, and slash commands live in `commands/`.

## Models

| Role | Model | Use |
| --- | --- | --- |
| `build`, `plan`, `architect` | `openai/gpt-5.6-sol` | Integration, architecture, planning, final decisions |
| `reviewer`, `investigator`, `security-reviewer` | `openai/gpt-5.6-terra` | Cross-file analysis, diagnosis, and review |
| `scout` | `openai/gpt-5.6-luna` | External documentation and upstream investigation |
| `general`, `explore`, `verifier` | `openai/gpt-5.3-codex-spark` | Bounded implementation, repository exploration, and verification |

Use Sol for integration, planning, and major design or architectural decisions, Terra for review and diagnosis spanning files/modules, Luna for external research, and Spark for bounded implementation, repository exploration, and verification workflows.

## Permissions

Reading is generally allowed, while environment files require confirmation. Shell commands are allowed by explicit allowlist and denied/asked otherwise. Git and GitHub write operations are not auto-approved globally.

External-directory access is denied by default. `/tmp/opencode` and `/tmp/opencode/**` require approval (`ask`) globally. This approval does not override an agent's `read`/`edit` permission settings.
All other external paths are denied unless explicitly configured later at the repository level.

Only `build` and `general` can edit the worktree. Read-only agents are read-only even through Bash by restricting Bash defaults to deny-state-changing commands. `build` and `plan` (primary agents) may start subagents. `subagent_depth` remains one.

`build` and `general` keep edit permission enabled for delegated local changes, but do not auto-allow sensitive write commands. GitHub Issue/PR/state-changing commands and destructive filesystem commands require explicit approval. Push, branch/rebase/reset operations, and remote writes are not globally auto-approved.

Commit, branch manipulation, `git push`, and GitHub Issue/PR changes require explicit user instruction and permission review.

## Standard Workflows

| Goal | Command |
| --- | --- |
| Clarify requirements | `/specify` |
| Implement an identified issue | `/issue <number-or-url>` |
| Review a change | `/review` |
| Address PR feedback | `/address-review <pr-number-or-url>` |
| Fix CI | `/fix-ci <pr-number-or-url>` |
| Debug behavior | `/debug <symptom>` |
| Publish a Draft PR | `/publish` |
| Prepare or publish a release | `/release [version]` |
| Update selected dependencies | `/deps <dependency-or-scope>` |
| Prepare and hand off an isolated worktree | `/worktree <task-or-branch>` |
| Backport selected commits | `/backport <commits> <target-branch>` |
| Create a threat model | `/threat-model <scope>` |
| Measure performance | `/benchmark <target>` |
| Run a staged migration | `/migrate <target>` |
| Audit a repository | `/repo-audit` |
| Audit this configuration | `/agent-audit` |

Review and audit workflows are read-only by default. Issue implementation never selects an issue and publication creates a Draft PR without merging.

## Parallel Subagents

The primary agent may delegate two to four independent workstreams concurrently when scopes are non-overlapping. Each worker must receive an exact scope, expected result, validation requirement, and prohibited changes. Work that edits the same file or depends on another workstream runs sequentially. `build` should prioritize delegation for repository exploration, bounded implementation, and verification instead of doing everything itself.

OpenCode does not isolate workers in separate worktrees, so file boundaries are prompt-enforced and parallel workers see shared changes. The primary agent must inspect returned diffs and execution results and own all final architecture/integration decisions.

- `build` must not assign overlapping files to concurrent workers.
- `build` should run `explore`, `general`, `verifier`, and `reviewer` in bounded form when those roles fit the subtask.
- Parent integration and final judgment stay with the parent agent; worker summaries alone are not enough evidence.

## Adding Configuration

Add an agent only when a role needs persistent model, permission, or editability properties that an existing agent cannot safely provide. Add a skill when multiple agents need a reusable workflow. Add a command only when users need an explicit workflow entry point, and keep it as a thin skill loader. Prefer extending an existing responsibility over creating overlapping reviewers or workers.

Do not put repository-specific commands, language conventions, file layouts, test naming, CI providers, specification-document assumptions, or fixed default branch names in this global configuration. Skills must discover project conventions from repository guidance, manifests, CI, tests, and Git metadata before acting.

## Updating Model IDs

Refresh and inspect provider models before changing an ID:

```sh
opencode models openai --refresh --verbose
```

Use the exact provider-prefixed IDs reported by the command. Confirm provider support before adding model-specific options.

## Validation

After editing this directory, restart OpenCode because configuration is loaded at startup. Then validate with:

```sh
jq empty config.d/opencode/opencode.json config.d/opencode/tui.json
opencode models openai --refresh --verbose
XDG_CONFIG_HOME="$PWD/config.d" opencode agent list
XDG_CONFIG_HOME="$PWD/config.d" opencode debug config
nix flake check --no-build

Optional focused checks:

- XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent build
- XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent general
- XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent explore
- XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent verifier
```

Confirm that all expected agents, skills, and commands are discovered, custom agent frontmatter uses `permission`, skill names match their directories, and no removed runtime references remain. Permission smoke tests require valid model credentials; report unavailable tests as unverified rather than successful.
