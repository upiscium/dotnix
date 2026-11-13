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

## Legacy nixpkgs database

If OpenCode prints `Detected legacy nixpkgs OpenCode database`, it is still using `opencode-stable.db` for compatibility. The [nixpkgs migration instructions](https://github.com/NixOS/nixpkgs/pull/558549) explain that the production channel normally uses `opencode.db`. Dotnix's launcher only synchronizes configuration; it does **not** migrate or back up the database. Changing the flake or setting `NIXPKGS_OPENCODE_DISABLE_LEGACY_DB_WORKAROUND=1` does not migrate sessions: it can make existing sessions appear to be missing.

This is a **manual, one-time migration of user data**, not a Home Manager activation step or a launch-time action:

1. Identify the affected user and data directory (`${XDG_DATA_HOME:-$HOME/.local/share}/opencode`), and check that `OPENCODE_DB` has not been set to a custom path. Stop **all** OpenCode processes for that user, including `opencode web`, and keep them stopped until the rename is complete.
2. Check that `opencode-stable.db` exists and `opencode.db` does **not** exist. Do not overwrite or merge a pre-existing canonical database; investigate which one has the sessions you need. If either path is a symlink, or SQLite sidecars (`opencode-stable.db-wal`, `opencode-stable.db-shm`, `opencode.db-wal`, or `opencode.db-shm`) remain after shutdown, stop and investigate rather than separating those files from the database or accidentally associating them with the renamed database.
3. Back up the **entire** OpenCode data directory (including any sidecar files and attachments) to a separate, private location. Check that the backup completed and can be restored before continuing. Keep the backup until the migrated sessions have been verified.
4. Immediately before changing anything, reconfirm that OpenCode is stopped, the backup is usable, and `opencode.db` is still absent. Rename `opencode-stable.db` to `opencode.db` in that same data directory; do not delete the legacy database or overwrite any existing canonical database. For example, after the checks above, run `mv -i "$data_dir/opencode-stable.db" "$data_dir/opencode.db"` with `data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/opencode"` set for the affected user. **Decline any overwrite prompt.**
5. Restart OpenCode, verify that `opencode db path` points to `opencode.db`, the expected sessions are present, and the warning is gone; retain the backup until satisfied. If verification fails, stop OpenCode again and plan a restore from the backup; preserve any data created since the backup before restoring, because a whole-directory restore could lose newer sessions. Do not blindly overwrite the migrated directory.

The workaround may be disabled **only if** you intentionally want to use another database or have already verified the migration; disabling it is not a substitute for moving the old sessions.

## Models

| Role | Model |
| --- | --- |
| `build`, `architect` | `openai/gpt-6-sol` |
| `security-reviewer` | `openai/gpt-5.6-terra` |
| `plan`, `reviewer`, `investigator`, `general`, `explore`, `verifier`, `scout` | `openai/gpt-6-luna` (`reasoningEffort: max`) |

Each global role has exactly one configured model. Model substitution, fallback agents, and retrying work under an alternate model are not part of this layer. If the configured provider/model cannot execute the task, report the exact failure and return `BLOCKED`.

The three local workers are separate OpenAI-compatible provider identities with conservative 32768-context/4096-output limits. They are Phase 1 manual/shadow advisory workers, not fallback capacity. OpenCode v1.18.16's public API cannot enforce `toolChoice=required`, so no plugin is installed; required-tool and same-agent/same-model one-retry enforcement remains in the parent workflow.

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
