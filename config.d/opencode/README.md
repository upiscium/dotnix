# OpenCode Global Configuration

This directory is deployed recursively to `~/.config/opencode/`. Changes apply to every repository and act as the **global user layer** for Dotnix.

## Source of truth

**Source of truth:** Templates behavior should not be duplicated; repository-local Templates configuration is authoritative.

- Dotnix is the **user-wide generic baseline and safe fallback**.
- Repository-local configuration, when present, performs deep-merge override and is authoritative.
- Generic repos have no Agent Core requirements.
- `review`, `audit`, `threat-model`, and `benchmark` remain global and read-only by default.

Templates currently has no repository-local `plan` workflow (separate issue candidate), so the global read-only plan path remains Agent-ready aware.

## Configuration Layers

- **Agents** define persistent execution properties: role, model, permissions, subagent depth, and required output boundaries.
- **Skills** define reusable workflows for agents to load. They do not set models or permissions.
- **Commands** are thin, user-initiated entry points that dispatch one or more skills.

Built-ins are discovered by OpenCode. `opencode.json` defines the global baseline schema/defaults/depth/permissions/provider. Global custom agents and built-in overrides live in `agents/*.md`; repository-local files with the same agent names override them in an Agent-ready repository. Reusable workflows live in `skills/`, and slash commands live in `commands/`.

## Models

Primary assignments:

| Role | Model |
| --- | --- |
| `build`, `plan`, `architect` | `openai/gpt-5.6-sol` |
| `reviewer`, `investigator`, `security-reviewer` | `openai/gpt-5.6-terra` |
| `general`, `explore`, `verifier`, `scout` | `openai/gpt-5.3-codex-spark` |

Model-name mapping used in this config: **Sol**=`openai/gpt-5.6-sol`, **Terra**=`openai/gpt-5.6-terra`, **Luna**=`openai/gpt-5.6-luna`, **Spark**=`openai/gpt-5.3-codex-spark`.

Fallback assignments:

- `build`, `plan`, `architect`, `reviewer`, `investigator`, `security-reviewer` → `Spark`
- `general`, `explore`, `verifier`, `scout` → `Luna`

Fallbacks cross model quota families: 5.6-primary roles fall back to Spark, while Spark-primary roles fall back to Luna. A 5.6 model never falls back to another 5.6 model.

`build-fallback` and `plan-fallback` are hidden primary-mode fallbacks selected manually when their active primary session encounters a classified usage limit. Other role fallbacks retry only the identical bounded objective and only for classified quota/rate-limit/HTTP 429 failures, never for authentication, permission, validation, context, tool, or safety failures.

There is no global task-orchestrator model binding.

## Task orchestration

Workflow shape is detected from repository context:

- **Generic repositories**: `Primary -> Leaf`.
- **Agent-ready repositories**: `Main -> Task Orchestrator -> Leaf`.

`subagent_depth` is 2 in this layer; generic repositories may use a single hop when needed.

## Agent-ready repository detection

Repository-local `Agent Core` guidance applies only when **both** files exist:

- `.automation/VERSION`
- `.automation/INIT.md`

If both are present, follow repository-local guidance, Agent Core conventions, and optional Task State context for workflow decisions. If either file is missing, treat the repository as generic and continue with global defaults.

These markers detect capability, not trust. OpenCode repository-local configuration can override global permissions, so inspect and trust the local Agent Core before opening an untrusted repository with project configuration enabled.

For any read-only workflow, **do not mutate Task State**.

## External directory

External directory access is denied by default. `/tmp/opencode` and `/tmp/opencode/**` require approval (`ask`) globally. This approval does not override an agent's own `read`/`edit` permissions.
All other external paths are denied unless explicitly allowed by local repository rules.

## Permissions and writes

- Reading is generally allowed, with environment files often confirmed.
- Shell inspection commands are allowed only where the role requires them; project-controlled test and build commands require confirmation globally.
- Git and GitHub write operations are generally **ask/confirm**, not auto-approved.
- Destructive filesystem and VCS operations are denied by default.
- In Agent-ready repos, repository-local config can further deny raw writes and require guarded `Just`-driven write APIs.

Do not use OpenCode auto-approval mode in untrusted repositories: auto-approval defeats the human review provided by global `ask` rules. Repository-local deny rules remain the authoritative stronger boundary in Agent-ready repositories.

Only `build`, `general`, and their role-equivalent fallback agents keep edit permission for delegated local modifications; other agents remain read-focused.
`plan` may start read-only inspection subagents only; executable verification is returned to the parent.

GitHub Issue/PR/state-changing commands and branch/reset/push-style operations are confirm-only globally.

## Workflows

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
| Start a task workflow | `/task-start <goal-or-scope>` |
| Execute an explicit scoped workflow or repository Task | `/task-run <workflow-or-task-id>` |

Behavior notes:

- `/issue` is the implementation flow.
- `/worktree` prepares an isolated workspace and hands off scoped tasks.
- `/publish` creates a Draft PR and does not merge.
- Review and audit workflows run read-only unless explicitly instructed otherwise.
- Commands remain thin skill entrypoints.

Split behavior:

- Agent-ready repositories (`.automation/VERSION` + `.automation/INIT.md`): `/issue` routes to local Task lifecycle and the Task Orchestrator; `/worktree` routes through task-start and does not execute raw worktree commands; `/publish` uses local guarded API publishing and never raw Git write calls.
- Generic repositories: use normal global command behavior and do not require Agent Core.

For `/task-run`, the argument contract is layer-specific: Generic mode uses `/task-run <workflow> [scope...]`; an Agent-ready repository's local command overrides it with `/task-run <TASK-ID>`.

## Parallelism

The primary agent may delegate independent task runs concurrently when scopes are non-overlapping. Each worker must receive an exact scope, expected result, validation requirement, and prohibited changes. Work that edits the same file or depends on another workstream runs sequentially.

Task worktree discovery and layout are repository-owned. `.worktrees` is an agent-ready local lifecycle convention, not a global fixed path.

- `build` must not assign overlapping files to concurrent workers.
- `build` should run `explore`, `general`, `verifier`, and `reviewer` in bounded form when those roles fit the subtask.
- Parent integration and final judgment stay with the parent agent; worker summaries alone are not enough evidence.

## Adding Configuration

Add an agent only when a role needs persistent model, permission, or editability properties that an existing agent cannot safely provide.
Add a skill when multiple agents need a reusable workflow.
Add a command only when users need an explicit workflow entry point, and keep it as a thin skill loader.

Do not put repository-specific commands, language conventions, file layouts, test naming, CI providers, specification assumptions, or fixed branch names in this global configuration. Skills discover repository conventions from local guidance, manifests, CI, tests, and Git metadata.

## Updating Model IDs

Refresh and inspect provider models before changing an ID:

```sh
opencode models openai --refresh --verbose
```

Use exact provider-prefixed IDs reported by the command. Confirm provider support before adding model-specific options.

## Validation

After editing this directory, restart OpenCode because configuration is loaded at startup. Then validate with:

```sh
jq empty config.d/opencode/opencode.json
jq empty config.d/opencode/tui.json
opencode models openai --refresh --verbose
XDG_CONFIG_HOME="$PWD/config.d" opencode agent list
XDG_CONFIG_HOME="$PWD/config.d" opencode debug config
```

The repository root is not itself a flake. Run the Nix check from each host flake instead:

```sh
(cd Adam && nix flake check --no-build)
(cd Caspar && nix flake check --no-build)
(cd Eve && nix flake check --no-build)
(cd Michael && nix flake check --no-build)
(cd Ramiel && nix flake check --no-build)
```

Optional focused checks:

```sh
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent build
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent plan
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent general
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent explore
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent verifier
XDG_CONFIG_HOME="$PWD/config.d" opencode debug agent reviewer
```

Depth-2 Ask smoke (issue -> local Task lifecycle/Task Orchestrator path) is a manual/global-readiness check in this layer; unless it is actually run, report status as **UNVERIFIED** / **INCOMPLETE** (not as passed).

Confirm that expected agents, skills, and commands are discovered, custom agent frontmatter uses `permission`, skill names match directories, and no stale runtime references remain.

Permission/agent smoke tests requiring external credentials should be run only when available. If not run, report as **INCOMPLETE**.
