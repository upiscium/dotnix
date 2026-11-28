# OpenCode Global Configuration

This directory is the package-owned source for dotnix's global OpenCode configuration. `packages/opencode/default.nix` synchronizes the entries in this directory into the user's normal OpenCode config directory before launching OpenCode. The runtime directory remains writable so OpenCode can manage its own dependency files, while these package-owned entries are refreshed from dotnix on every launch.

## Ownership and precedence

- Dotnix owns the **global user baseline** for generic repositories.
- Repository-local OpenCode configuration remains authoritative and may impose stronger rules.
- Agent-ready repositories are detected when both `.automation/VERSION` and `.automation/INIT.md` exist.
- Repository-local systems own their own lifecycle, permissions, safety policy, and validation; do not duplicate those contracts here.
- There is no shared upiscium-owned OpenCode policy authority between dotnix and repository-local configurations.
- Environment capabilities provided here may be consumed opportunistically, but their presence does not define repository-local correctness.

Keeping this configuration in the standard global OpenCode path is intentional. OpenCode loads the global layer before repository-local `.opencode` configuration, so repository-local configuration can continue to override this baseline.

## Configuration layers

- `opencode.json` defines the global schema, providers, permissions, defaults, and depth.
- `tui.json` defines TUI-specific preferences and keybindings.
- `agents/*.md` defines persistent agent role/model/permission properties.
- `skills/*/SKILL.md` defines reusable workflows.
- `commands/*.md` defines thin user-invoked entry points into skills.
- `local-workers.toml` defines the disabled-by-default, manual/shadow local-worker manifest. Local roles are available only through the explicit local-worker workflow.

OpenCode-generated runtime files such as `.gitignore`, `node_modules`, package metadata, and lock files are not package-owned and are preserved by the dotnix launcher.

## Models

All roles run on TSUMGI. The `openai` provider is disabled (`disabled_providers`), so OpenCode cannot fall back to it.

| Role | Model | Why |
| --- | --- | --- |
| `build`, `plan`, `architect`, `security-reviewer`, `reviewer`, `investigator` | `tsumgi/qwen3.8-27b` | 128K context on polaris (2x RTX 3060, llama.cpp, about 28 tok/s, working prefix cache) for the roles that read the most code |
| `general`, `explore`, `scout`, `verifier` | `tsumgi/qwen3.8-flash-next-coder` | 128K on two separate 2-GPU lanes (canopus, deneb), so parallel subagents do not queue behind the primary agent |

No role sets `reasoningEffort`: TSUMGI serves the short Qwen3.6 profile and the 27B profile with thinking off and the Coder profile with thinking always on, and the option has no effect on any of them. Each TSUMGI profile serves one request at a time, so parallel subagents on the same profile run one after another.

Each global role has exactly one configured model. Model substitution, fallback agents, and retrying work under an alternate model are not part of this layer. If the configured provider/model cannot execute the task, report the exact failure and return `BLOCKED`.

The three hidden local workers use the shared `tsumgi` OpenAI-compatible provider, with explicitly pinned model IDs. They remain Phase 1 manual/shadow read-only advisory workers, not fallback capacity. Each worker is pinned to a different TSUMGI profile, so the three can run at the same time on different hosts: `local-investigator` uses `qwen3.8-27b`, `local-tracer` uses `qwen3.8-flash-next-coder`, and `local-background` uses `qwen3.6-35b-a3b-short`. TSUMGI owns deployment routing and scheduling. The original `ollama` and `local-quality` / `local-fast` / `local-background` provider definitions and `agent-runtime` services are retained temporarily for a controlled rollback, but the active local-worker manifest does not reference them. OpenCode's public API cannot enforce `toolChoice=required`, so no plugin is installed; required-tool and same-agent/same-model one-retry enforcement remains in the parent workflow.

## TSUMGI model access (Qwen3.6 profiles, TSUMGI v0.2.0-rc.1, 2026-11-16)

The TSUMGI Gateway is configured at `https://tsumgi.arc.upiscium.dev/v1`. Bonsai 2, the 64K Qwen3.6 profile (`qwen3.6-35b-a3b`, retired 2026-11-24), the 192K Qwen3.6 profile (`qwen3.6-35b-a3b-fast`, retired 2026-11-25) and the Coder fast profile (`qwen3.8-flash-next-coder-fast`, retired 2026-11-27) are retired. The short profile (Qwen3.6-35B-A3B) and the 27B profile (Qwen3.8-27B) run with thinking off; `qwen3.8-flash-next-coder` serves the Qwen3.8 Flash-Next Coder model with thinking on:

| Model ID | Host and runtime | `limit.context` (total) | Output | Speed |
| --- | --- | --- | --- | --- |
| `qwen3.8-27b` | polaris, llama.cpp (2x RTX 3060, tensor split, KV q8_0) | 131,072 (input up to 122,880) | 8,192 | about 28 tok/s (17 at 100K); prompt reading about 650 tok/s; thinking off |
| `qwen3.6-35b-a3b-short` | spica, Strata | 12,288 | 2,048 | 26-34 tok/s |
| `qwen3.8-flash-next-coder` | canopus and deneb, Strata (2x GTX 1080 Ti each, layer split) | 131,072 | 8,192 | about 40 tok/s; thinking always on |

The OpenCode `limit.context` value is the *total* model budget the Gateway advertises in `GET /v1/models`, not the separate maximum input. Each profile runs on one host with one request at a time, so concurrent sessions on the same profile queue in the Gateway. While a long prompt is being read, the Gateway keeps streams alive with SSE comments; non-streaming requests depend on the reverse proxy's 1800 s timeout.

Because dotnix's OpenCode launcher restores package-owned global configuration on each invocation, editing `~/.config/opencode/opencode.json` directly will not persist. Change this source file and deploy the reviewed dotnix package instead.

**Coupled rollback:** if TSUMGI moves a profile to a smaller context, lower that model's `limit.context` here in the same change window and redeploy the package on each affected host. Old running OpenCode sessions keep their previous budgets until relaunched. The Gateway's strict token admission still fails closed while clients are temporarily inconsistent.

Choose `--agent tsumgi-fast`, `--agent tsumgi-short` or `--agent tsumgi-coder` for manual TSUMGI sessions. These primary agents are read-only and omit `reasoningEffort`, because passing an OpenAI-tuned primary agent's `reasoningEffort: high` option to a TSUMGI model was observed to yield HTTP 400 (`unsupported_field`). The canonical roles above already run on TSUMGI without `reasoningEffort`; these three agents remain for explicit read-only sessions pinned to one profile.

No API key was needed for the verified requests from Balthazar; consequently the `tsumgi` provider has no embedded token. Verify gateway ingress restrictions independently before treating this as safe for arbitrary network clients. If TSUMGI client authentication is enabled in the future, supply a client token via a protected environment variable (for example `{env:TSUMGI_CLIENT_TOKEN}`), not a committed secret.

## KASANE knowledge (MCP)

`opencode.json` registers the KASANE MCP server (`kasane`), and `AGENTS.md` holds the global instructions for using it. OpenCode loads `~/.config/opencode/AGENTS.md` as global rules in addition to repository-local `AGENTS.md`; repository-local rules take precedence. The Claude Code side uses the same instruction text in `~/.claude/CLAUDE.md`.

- The server runs from the KASANE checkout at `~/src/KASANE` against `~/.local/state/KASANE/vault.db`. On a host without them, the server fails at startup and OpenCode continues without the `kasane_*` tools.
- `--default-scope global` only: agents name their project scope in each request, so knowledge from one project is not served to another by default.
- One server process serves every role in an OpenCode process, so `KASANE_MODEL` cannot name the model of each role. It lists the OpenAI models of the roles (`openai/gpt-6.1-sol,openai/gpt-6-luna`); update it together with the model table above.
- `KASANE_SESSION` is unset, so each OpenCode process is a new KASANE session (the weak-independence risk documented in KASANE `docs/mcp.md`).

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
| Explicit local-worker dispatch | `/local-worker <worker> <read-or-grep> <bounded-objective>` |

Commands remain thin entry points. Agent-ready repositories may override command semantics with their guarded local lifecycle.

## Updating model IDs

Refresh the provider model list before changing IDs:

```sh
opencode models tsumgi --refresh --verbose
```

Use exact provider-prefixed IDs reported by OpenCode. Model/provider choices in this Global layer are dotnix-owned environment configuration, not a cross-repository contract.

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

Validate the dotnix-owned Global permission and agent contracts, then evaluate
the root flake:

```sh
python3 -m unittest discover -s tests -p 'test_opencode*.py' -v
nix flake check --all-systems --no-build --no-update-lock-file
```

For Home Manager integration, build/switch an actual host and verify that `which opencode` resolves to the configured package. Restart OpenCode after source changes because configuration is loaded at startup.

Depth-2 Ask and credential-dependent provider/permission smoke tests are manual checks. If they are not run, report them as **UNVERIFIED** / **INCOMPLETE** rather than passed.
