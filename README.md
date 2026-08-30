# dotnix

## Repository structure

- The root `flake.nix` owns portable package outputs, repository-level policy validation, minimal development tooling, and CI.
- Host directories such as `Adam/`, `Caspar/`, `Eve/`, `Michael/`, and `Ramiel/` retain authority for their NixOS and Home Manager configurations, inputs, and lockfiles.
- `packages/` contains self-contained configured application artifacts consumed by host-local Home Manager configurations or through the root flake.
- `config.d/` contains legacy/shared configuration that has not yet been moved to its final semantic owner. Configured portable applications should live under `packages/<name>/` instead.

The root flake does not aggregate hosts, expose `nixosConfigurations` or `homeConfigurations`, consolidate host inputs, or own deployment. Its package outputs are reusable artifacts only; host-local flakes remain the deployment authority.

## Portable package contract

The root flake targets:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

`x86_64-darwin` is deliberately excluded because the pinned Nixpkgs line no longer supports Intel Darwin. Platform-specific dependencies stay inside package definitions and must not leak into callers.

Configured packages are auto-discovered from `packages/<name>/default.nix`. A package may restrict publication with `packages/<name>/systems.nix` when its supported platform subset is narrower than the root contract.

Current configured packages include:

- `neovim`: Linux + Apple Silicon Darwin
- `tmux`: Linux + Apple Silicon Darwin
- `kitty`: Linux only
- `starship`: Linux + Apple Silicon Darwin
- `waybar`: Linux only
- `opencode`: Linux + Apple Silicon Darwin

`just` is exposed separately as a bootstrap utility.

## Direct installation

```sh
nix profile add github:upiscium/dotnix#neovim
nix profile add github:upiscium/dotnix#tmux
nix profile add github:upiscium/dotnix#kitty
nix profile add github:upiscium/dotnix#starship
nix profile add github:upiscium/dotnix#opencode
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

Without Just installed:

```sh
nix develop -c just list
nix develop -c just build opencode
```

## Package ownership

### Neovim

`packages/neovim/` owns the configured editor, Lua configuration, providers, LSP/tooling closure, and MCPHub configuration. `lazy.nvim` plugin acquisition remains runtime-managed.

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

Home Manager only installs the configured package through `packages/opencode/home.nix`; it no longer recursively deploys `~/.config/opencode` from `config.d`.

## OpenCodePolicy

dotnix pins [`upiscium/OpenCodePolicy`](https://github.com/upiscium/OpenCodePolicy) through the root `flake.lock` and explicitly conforms to the `global` profile. OpenCodePolicy owns shared policy/compatibility contracts; dotnix remains implementation owner of the global OpenCode layer under `packages/opencode/config/`.

The dependency is validation-only. It does not generate or materialize agents, prompts, commands, skills, provider settings, or TUI configuration.

The global profile enforces fixed Sol/Terra/Luna assignments. Spark, fallback agents, model substitution, and alternate-model retry are not part of the contract; an unavailable configured model must report the exact provider/model failure and return `BLOCKED`.

After `nix develop`:

```sh
opencode-policy validate
opencode-policy audit-consumer --profile global --consumer . --strict
```

## Updating policy

OpenCodePolicy advances only through an explicit dependency update. The recommended path is the manual **GitHub Actions → Update OpenCodePolicy → Run workflow** action on `main`, or:

```sh
gh workflow run update-opencode-policy.yml \
  --repo upiscium/dotnix \
  --ref main
```

For a local update:

```sh
nix flake update opencodePolicy
nix flake check --no-update-lock-file
opencode-policy audit-consumer --profile global --consumer . --strict
```

Review the root `flake.lock` diff before merging. Host-local lockfiles must not be updated as part of the policy workflow.
