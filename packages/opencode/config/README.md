# OpenCode Global Configuration

This directory is the package-owned source for dotnix's global OpenCode configuration. `packages/opencode/default.nix` synchronizes the entries in this directory into the user's normal OpenCode config directory before launching OpenCode. The runtime directory remains writable so OpenCode can manage its own dependency files, while these package-owned entries are refreshed from dotnix on every launch.

## Ownership and precedence

- Dotnix owns the **global user baseline** for generic repositories.
- Repository-local OpenCode configuration remains authoritative and may impose stronger rules.
- Agent-ready repositories are detected when both `.automation/VERSION` and `.automation/INIT.md` exist.
- Templates owns Agent Core behavior; do not duplicate Templates-specific lifecycle or repository policy here.
- OpenCodePolicy owns shared compatibility contracts, not the complete implementation.

Keeping this configuration in the standard global OpenCode path is intentional. OpenCode loads the global layer before repository-local `.opencode` configuration, so repository-local configuration can continue to override this baseline.

## Configuration layers

- `opencode.json` defines the global schema, providers, permissions, defaults, and depth.
- `tui.json` defines TUI-specific preferences and keybindings.
- `agents/*.md` defines persistent agent role/model/permission properties.
- `skills/*/SKILL.md` defines reusable workflows.
- `commands/*.md` defines thin user-invoked entry points into skills.

OpenCode-generated runtime files such as `.gitignore`, `node_modules`, package metadata, and lock files are not package-owned and are preserved by the dotnix launcher.

## Models

| Role | Model |
| --- | --- |
| `build`, `plan`, `architect` | `openai/gpt-5.6-sol` |
| `reviewer`, `investigator`, `security-reviewer` | `openai/gpt-5.6-terra` |
| `general`, `explore`, `verifier`, `scout` | `openai/gpt-5.6-luna` |

Each global role has exactly one configured model. Model substitution, fallback agents, and retrying work under an alternate model are not part of this layer. If the configured provider/model cannot execute the task, report the exact failure and return `BLOCKED`.

## Authority boundary

Generic repositories normally use `Primary -> Leaf`. Agent-ready repositories may use `Main -> Task Orchestrator -> Leaf` according to their repository-local Agent Core configuration.

External directory access is denied by default. `/tmp/opencode` and `/tmp/opencode/**` require approval globally; repository-local policy can be stricter. Git/GitHub state-changing operations are confirm-only globally, and destructive filesystem/VCS operations are denied by default.

Only roles explicitly configured for implementation retain edit authority. Review, investigation, verification, architecture, and security-review roles remain read-focused. Read-only workflows must not mutate Task State.

## Commands

| Goal | Command |
| --- | --- |
| Clarify requirements | `/specify` |
| Implement an issue | `/issue <number-or-url>` |
| Review a change | `/review` |
| Address PR feedback | `/address-review <pr-number-or-url>` |
| Fix CI | `/fix-ci <pr-number-or-url>` |
| Debug behavior | `/debug <symptom>` |
| Publish a Draft PR | `/publish` |
| Prepare/publish a release | `/release [version]` |
| Update dependencies | `/deps <dependency-or-scope>` |
| Prepare an isolated worktree | `/worktree <task-or-branch>` |
| Backport commits | `/backport <commits> <target-branch>` |
| Create a threat model | `/threat-model <scope>` |
| Measure performance | `/benchmark <target>` |
| Run a migration | `/migrate <target>` |
| Audit a repository | `/repo-audit` |
| Audit this configuration | `/agent-audit` |
| Start a task workflow | `/task-start <goal-or-scope>` |
| Execute a scoped workflow/task | `/task-run <workflow-or-task-id>` |

Commands remain thin entry points. Agent-ready repositories may override command semantics with their guarded local lifecycle.

## Updating model IDs

Refresh the provider model list before changing IDs:

```sh
opencode models openai --refresh --verbose
```

Use exact provider-prefixed IDs reported by OpenCode and keep OpenCodePolicy conformity intact.

## Validation

Validate source files directly:

```sh
jq empty packages/opencode/config/opencode.json
jq empty packages/opencode/config/tui.json
nix develop -c just build opencode
```

Validate the standalone configured launcher without touching the normal user config by using a temporary XDG config root:

```sh
TMP_CONFIG="$(mktemp -d)"
XDG_CONFIG_HOME="$TMP_CONFIG" ./result/bin/opencode agent list
XDG_CONFIG_HOME="$TMP_CONFIG" ./result/bin/opencode debug config
```

The wrapper should create `$TMP_CONFIG/opencode`, materialize the package-owned entries there, and leave OpenCode-generated dependency/runtime files writable.

Validate repository policy and package publication from the root flake:

```sh
nix flake check --all-systems --no-build --no-update-lock-file
opencode-policy audit-consumer --profile global --consumer . --strict
```

For Home Manager integration, build/switch an actual host and verify that `which opencode` resolves to the configured package. Restart OpenCode after source changes because configuration is loaded at startup.

Depth-2 Ask and credential-dependent provider/permission smoke tests are manual checks. If they are not run, report them as **UNVERIFIED** / **INCOMPLETE** rather than passed.
