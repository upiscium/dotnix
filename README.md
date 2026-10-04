# dotnix

## Repository structure

- The root `flake.nix` owns portable package outputs, repository-level policy validation, minimal development tooling, and CI.
- Host directories such as `Adam/`, `Caspar/`, `Eve/`, `Michael/`, and `Ramiel/` retain authority for their NixOS and Home Manager configurations, inputs, and lockfiles.
- `packages/` contains self-contained configured application artifacts consumed by host-local Home Manager configurations or through the root flake.
- `common/home/` owns shared user-level Home Manager configuration and retained user-level reference data.
- `module/home/` and `module/host/` own reusable Home Manager and NixOS integration respectively.
- A root `config.d/` directory is intentionally forbidden. Configuration must live with its semantic owner; root flake checks reject reintroduction of `config.d/`.

The root flake does not aggregate hosts, expose `nixosConfigurations` or `homeConfigurations`, consolidate host inputs, or own deployment. Its package outputs are reusable artifacts only; host-local flakes remain the deployment authority.

## Portable package contract

The root flake targets:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

`x86_64-darwin` is deliberately excluded because the pinned Nixpkgs line no longer supports Intel Darwin. Platform-specific dependencies stay inside package definitions and must not leak into callers.

Configured packages are auto-discovered from `packages/<name>/default.nix`. A package may restrict publication with `packages/<name>/systems.nix` when its supported platform subset is narrower than the root contract. Use `just list` or inspect the flake outputs for the canonical, currently available package set.

The current human-readable package overview is:

- `kitty`: Linux only
- `neovim`: Linux + Apple Silicon Darwin
- `opencode`: Linux + Apple Silicon Darwin
- `starship`: Linux + Apple Silicon Darwin
- `tmux`: Linux + Apple Silicon Darwin
- `waybar`: Linux only

`just` is exposed separately as a bootstrap utility.

## Direct installation

Install any exposed package directly. These are representative examples, not an exhaustive package inventory:

```sh
nix profile add github:upiscium/dotnix#neovim
nix profile add github:upiscium/dotnix#waybar
```

The installer app installs from the exact dotnix revision used to launch it:

```sh
nix run github:upiscium/dotnix#install -- opencode
nix run github:upiscium/dotnix#install -- just
```

Set `DOTNIX_PROFILE` to target an isolated profile instead of the user's default profile.

## Just frontend

The root `justfile` is the human-facing CLI and Nix remains the build/install authority:

```sh
just list
just check
just build neovim
just build opencode
just run opencode
just install opencode
just install-remote opencode
just profile
```

`just check` runs the normal no-build repository validation: repository contract tests, the package registry contract tests, and all-system flake evaluation. CI reuses the same validation authority and keeps build-time gates separate.

Without Just installed:

```sh
nix develop -c just list
nix develop -c just check
nix develop -c just build opencode
```

## Configuration ownership

Configured standalone applications belong under `packages/<name>/`. Shared user-level configuration that only exists through Home Manager belongs under `common/home/`. Desktop/session integration belongs under the corresponding `module/home/` owner, and host-side shared data belongs under `common/host/` or a host-local directory when it is machine-specific.

A few inactive configurations are retained without being deployed:

- `common/home/vscode/`: historical VS Code user settings/keybindings.
- `module/home/hyprland/walker/`: historical Walker launcher configuration/theme.
- `common/home/ssh-pubkeys/`: public-key reference material; this is intentionally outside the recursively deployed `common/home/ssh/` tree.

Retained inactive configuration does not imply that the corresponding application is installed or managed. It should only be wired into Home Manager or promoted to `packages/<name>/` when the application becomes active again.

## Package ownership

### Neovim

`packages/neovim/` owns the configured editor, Lua configuration, providers, LSP/tooling closure, and MCPHub configuration. `lazy.nvim` plugin acquisition remains runtime-managed.

### Tmux

`packages/tmux/` owns the configured Tmux wrapper and immutable `config/tmux.conf`; the wrapper starts Tmux with that package-owned configuration. `packages/tmux/home.nix` only installs the configured package rather than maintaining a second Tmux configuration.

### Kitty

`packages/kitty/` owns the configured Kitty wrapper and immutable config directory. It is currently Linux-only until the macOS application-bundle launch path is validated.

### Starship

`packages/starship/` owns the configured Starship executable/configuration. Home Manager retains only shell integration.

### Waybar

`packages/waybar/` owns the top/bottom bar configurations and provides `waybar-top` / `waybar-bottom` launchers. The upstream `waybar` CLI remains available for debugging.

### OpenCode

`packages/opencode/` owns the global OpenCode implementation. `config/` is the repository source of truth for global agents, commands, skills, provider/permission configuration, and TUI preferences.

OpenCode needs writable configuration directories because it manages plugin dependencies at runtime. The packaged launcher therefore synchronizes only dotnix-owned top-level entries into the normal user config directory (`$XDG_CONFIG_HOME/opencode`, or `~/.config/opencode`) before starting upstream OpenCode. OpenCode-generated `.gitignore`, dependency directories, package metadata, and lockfiles are preserved. Package-owned entries are refreshed on every launch, so repository state remains authoritative.

The launcher deliberately does not use `OPENCODE_CONFIG_DIR` for the global baseline. Keeping the baseline in OpenCode's normal global config directory preserves OpenCode's merge ordering: global configuration loads before repository-local `.opencode`, allowing repository-local policy to remain authoritative.

Home Manager only installs the configured package through `packages/opencode/home.nix`; it no longer recursively deploys the global OpenCode implementation from a root configuration directory.

## OpenCode repository boundary

dotnix owns only the Global/user OpenCode baseline under `packages/opencode/`.
That baseline must be independently coherent for generic repositories, but it is
not a policy authority for repository-local systems.

Repository-local OpenCode configurations own their own correctness, permissions,
agent lifecycle, guarded operations, and validation. They may consume capabilities
provided by the current environment—such as provider credentials, model
assignments, Local-LLM-backed agents, caches, or accelerators—but those
capabilities are optional unless the repository explicitly declares a functional
dependency on them. Their absence must not silently weaken repository-local
correctness or safety.

There is intentionally no upiscium-owned cross-repository OpenCode policy
contract. Similar role names, model choices, or permission rules may be duplicated
across repositories when each repository needs them. Such similarity does not
create shared ownership or synchronization requirements.

For Global OpenCode changes, validate the dotnix-owned configuration directly:

```sh
python3 -m unittest discover -s tests -p 'test_opencode*.py' -v
nix flake check --all-systems --no-build --no-update-lock-file
```

Local provider/model/endpoint definitions remain dotnix-owned environment
configuration. Repository-local consumers must not require access to those
details merely to remain functional.
