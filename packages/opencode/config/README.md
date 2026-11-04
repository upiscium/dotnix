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

| Role | Model | Reasoning effort |
| --- | --- | --- |
| `build`, `plan`, `architect`, `security-reviewer` | `openai/gpt-6.1-sol` | `high` |
| `reviewer`, `investigator` | `openai/gpt-6-luna` | `high` |
| `general`, `explore`, `scout`, `verifier` | `openai/gpt-6-luna` | `medium` |

Each global role has exactly one configured model. Model substitution, fallback agents, and retrying work under an alternate model are not part of this layer. If the configured provider/model cannot execute the task, report the exact failure and return `BLOCKED`.

The three hidden local workers use the shared `tsumgi` OpenAI-compatible provider, with explicitly pinned model IDs. They remain Phase 1 manual/shadow read-only advisory workers, not fallback capacity. TSUMGI owns deployment routing and scheduling; `local-tracer` and `local-background` currently share the `bonsai2-27b` serving profile, with no separate speed or GPU-affinity guarantee. The original `ollama` and `local-quality` / `local-fast` / `local-background` provider definitions and `agent-runtime` services are retained temporarily for a controlled rollback, but the active local-worker manifest does not reference them. OpenCode v1.18.16's public API cannot enforce `toolChoice=required`, so no plugin is installed; required-tool and same-agent/same-model one-retry enforcement remains in the parent workflow.

## TSUMGI model access (verified 2026-11-01)

The TSUMGI Gateway is configured at `https://tsumgi.arc.upiscium.dev/v1`. Live `GET /v1/models` from Adam returned exactly `qwen3.8-27b` and `bonsai2-27b`, each advertising `tools`, 6,144 input tokens, 2,048 output tokens, 8,192 total tokens and a 65,536-byte request limit. The OpenCode `limit.context` value is the 8,192-token total budget, not the separate 6,144-token input limit.

Both models passed bounded plain chat, streamed chat, and structured tool-call HTTP probes. An isolated OpenCode 1.18.35 `run` plain-chat probe passed for each model. These checks do not establish arbitrary coding quality, automatic dispatch or workload performance.

Choose `--agent tsumgi-qwen` or `--agent tsumgi-bonsai` for manual TSUMGI sessions. Both primary agents are read-only and omit `reasoningEffort`. The old HTTP 400 `unsupported_field` observation applied **before** [TSUMGI #209](https://github.com/upiscium/TSUMGI/issues/209); as of v0.1.3, the Gateway accepts bounded `reasoning_effort: low|medium|high` as a **no-effect compatibility hint**, not as a model reasoning-budget control. An independent input-budget failure can still occur when overriding the OpenAI-oriented `plan` Agent's model. The canonical OpenAI `build` and `plan` model assignments must not be changed or silently routed to TSUMGI. Track the client-specific context issue in [dotnix #68](https://github.com/upiscium/dotnix/issues/68).

### TSUMGI input-context budget: bounded investigation (#68)

Both logical models advertise **6,144 effective input tokens**, **2,048 output tokens**, **8,192 total context tokens**, and a separate **65,536-byte HTTP request limit**. This is not a promise that 8,192 tokens can be used for the input. In particular, Tool schemas and agent/system instructions contribute to actual prompt tokens. A JSON request below the byte limit can still exceed the input-token limit and fail closed with `context_length_exceeded`.

On 2026-11-04 JST, OpenCode **1.18.35** on Adam (dotnix `c1b30e6`) sent synthetic requests for a single identical, harmless instruction to a loopback-only ChatCompletions receiver. The receiver returned fabricated SSE data; **no production inference or model request was sent, and raw prompts, Tool schemas, keys and client headers were not retained**. The first automatic 0-tool auxiliary request was distinguished from the subsequent main Agent request. Numeric main-request shapes were:

| Selected Agent and model | Main request bytes | Messages bytes | Tool schema bytes | Tool count | `reasoning_effort` |
| --- | ---: | ---: | ---: | ---: | --- |
| `plan` forced onto `tsumgi/qwen3.8-27b` | 29,654 | 18,536 | 10,955 | 6 | `high` (no effect) |
| `tsumgi-qwen` with `tsumgi/qwen3.8-27b` | 5,218 | 1,046 | 4,035 | 3 | absent |
| `tsumgi-bonsai` with `tsumgi/bonsai2-27b` | 5,220 | 1,048 | 4,035 | 3 | absent |

The `plan` request is about **5.7×** larger in bytes than the dedicated local Qwen request; it uses a longer system/Agent prompt and more tools. The ~29.7 KB request size and six-tool shape also resemble previous rejected production jobs. These measurements establish **request shape, not exact model-tokenizer counts, client attribution or a causal proof**. The deployed llama.cpp backend enforces its input budget using the tokenizer-aware `/v1/chat/completions/input_tokens` endpoint, which was not directly accessible during this probe.

**Operator guidance:** use explicit dedicated `tsumgi-qwen` / `tsumgi-bonsai` Agents for bounded local tasks; use canonical OpenAI `plan` for workflows requiring its larger prompt and tool surface. Do not reassign `plan` to TSUMGI, automatically fall back to a different model, delete tools without workflow review, weaken Gateway validation, or silently increase GPU context/VRAM commitments. Before adjusting routing, measure a reproducible main-request **actual input-token count** with the pinned model's tokenizer and compare against 6,144, including the Tool schemas and system instructions, without capturing user prompts or secrets. Source of investigation and aggregate fleet evidence: [dotnix #68](https://github.com/upiscium/dotnix/issues/68).

No API key was needed for the verified requests from Adam; consequently the `tsumgi` provider has no embedded token. Verify gateway ingress restrictions independently before treating this as safe for arbitrary network clients. If TSUMGI client authentication is enabled in the future, supply a client token via a protected environment variable (for example `{env:TSUMGI_CLIENT_TOKEN}`), not a committed secret.


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
opencode models openai --refresh --verbose
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
