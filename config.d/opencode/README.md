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
| `general`, `explore`, `scout`, `verifier` | `openai/gpt-5.6-luna` | Bounded implementation, search, research, and verification |

Use Luna for clear bounded work, Terra for analysis spanning files or modules, and Sol only for consequential design or integration decisions.

## Permissions

Reading is generally allowed, while environment files require confirmation. Shell commands ask by default. Git inspection, staging, fetch and pull; read-only GitHub and OpenCode queries; selected GitHub Issue and PR writes; and common project test, lint, check, type-check, build, evaluation, and validation commands are automatically allowed with arguments. GitHub release creation and upload remain confirmation-gated. Common spellings of destructive filesystem and Git operations, history rewriting, force-push, direct pushes to common default-branch names, and privilege escalation are denied. Bash permissions are approval gates rather than a complete sandbox; repository-local configuration can override these global defaults and is therefore trusted.

Only `build` and `general` edit the worktree. Only primary agents (`build` and `plan`) may start subagents. `subagent_depth` is one, so subagents cannot create another generation. `build` may push automatically after an explicit user request and a branch-safety check; subagents may not push. Explicit main/master and force-push forms remain denied, but a bare `git push` requires the agent to detect the current and default branches because permission patterns cannot inspect Git state. Commits, remote publication, and merges still require an explicit user workflow. No workflow merges automatically.

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

The primary agent may delegate two to four independent workstreams concurrently. Each worker must receive an exact scope, expected result, validation requirement, and prohibited changes. Work that edits the same file or depends on another workstream runs sequentially. OpenCode does not isolate workers in separate worktrees, so file boundaries are prompt-enforced and parallel workers see shared changes. The primary agent must inspect all returned diffs and owns integration; worker summaries are not accepted as evidence by themselves.

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
nix flake check --no-build
```

Confirm that all expected agents, skills, and commands are discovered, custom agent frontmatter uses `permission`, skill names match their directories, and no removed runtime references remain. Permission smoke tests require valid model credentials; report unavailable tests as unverified rather than successful.
