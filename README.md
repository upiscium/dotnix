# dotnix

## Repository structure

- The root `flake.nix` owns portable package outputs, repository-level policy validation, minimal development tooling, and CI.
- Host directories such as `Adam/`, `Caspar/`, `Eve/`, `Michael/`, and `Ramiel/` retain authority for their NixOS and Home Manager configurations, inputs, and lockfiles.
- `packages/` contains self-contained application artifacts that can be consumed by host-local NixOS/Home Manager configurations or through the root flake.
- `config.d/opencode/` remains the deployed global OpenCode implementation. Home Manager deployment continues to be owned by `common/home/terminal.nix`.

The root flake does not aggregate hosts, expose `nixosConfigurations` or `homeConfigurations`, consolidate host inputs, or own deployment. Its package outputs are reusable artifacts only; host-local flakes remain the deployment authority.

## Portable package contract

The root flake targets the platforms supported by the pinned unstable Nixpkgs that are relevant to this repository:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

`x86_64-darwin` is deliberately not part of the primary contract because Nixpkgs 26.11 dropped Intel Darwin support. If an Intel Mac needs to be supported later, it should use an explicit legacy Nixpkgs lane rather than silently pinning the whole repository back to an older package set.

A package published as `packages.<system>.<name>` is intended to be consumable independently of the host-local NixOS/Home Manager configurations. Platform-specific dependencies must stay inside the package definition and must not leak into callers.

The currently published application package is `neovim`. `just` is also exposed as a bootstrap utility for the repository CLI.

### Direct installation

On a supported Linux or Apple Silicon macOS machine with Nix and flakes enabled, a published package can be installed directly from GitHub without cloning this repository:

```sh
nix profile add github:upiscium/dotnix#neovim
```

The installer app provides the same package from the exact dotnix revision used to launch it:

```sh
nix run github:upiscium/dotnix#install -- neovim
```

To bootstrap the Just frontend itself:

```sh
nix run github:upiscium/dotnix#install -- just
```

Set `DOTNIX_PROFILE` when an install/remove/profile operation should target an isolated Nix profile instead of the user's default profile. This is useful for tests and for machines where Home Manager owns the normal user environment:

```sh
DOTNIX_PROFILE=/tmp/dotnix-test-profile \
  nix run github:upiscium/dotnix#install -- just
```

### Just frontend

When working from a clone, `justfile` is the human-facing interface and Nix remains the build/install authority:

```sh
just list
just check
just build neovim
just run neovim
just install neovim
just install-remote neovim
just profile
```

If `just` is not installed yet, it is available through the root development shell:

```sh
nix develop -c just list
nix develop -c just install neovim
```

`just install <package>` installs the package from the checked-out repository revision. `just install-remote <package>` installs from `github:upiscium/dotnix` instead. The `install`, `install-remote`, `remove`, and `profile` recipes honor `DOTNIX_PROFILE`.

## Neovim package

The configured Neovim environment is owned by `packages/neovim/`:

- `default.nix` builds the standalone wrapped Neovim derivation.
- `config/` owns the Lua configuration previously stored under `config.d/nvim/` and the packaged MCPHub runtime configuration.
- `home.nix` is the thin Home Manager integration used by `common/home/`.

The package includes the Neovim providers plus the LSP servers, formatters, compilers, and command-line tools that were previously supplied by `common/home/neovim.nix`. Linux-only runtime dependencies such as `glibc` and GCC are kept conditional inside the package so Darwin callers do not inherit Linux assumptions.

It can be built or run independently:

```sh
nix build .#neovim
nix run .#neovim
```

The existing `lazy.nvim` bootstrap remains runtime-managed, so Neovim plugins are still acquired at runtime. The standalone package therefore makes the editor, configuration, providers, LSPs, formatters, MCPHub configuration, and supporting executables reproducible, but plugin acquisition is not yet fully Nix-managed.

## OpenCodePolicy

dotnix pins [`upiscium/OpenCodePolicy`](https://github.com/upiscium/OpenCodePolicy) through the root `flake.lock` and explicitly conforms to the `global` profile. OpenCodePolicy owns the shared policy and compatibility contract; dotnix remains the global OpenCode implementation owner.

The dependency is validation-only. It does not generate or materialize agents, prompts, commands, skills, provider settings, or any other file under `config.d/opencode/`.

The `global` profile enforces the fixed Sol/Terra/Luna role assignments used by dotnix. It does not permit Spark, fallback agents, model substitution, or alternate-model retries; an unavailable configured model must report the exact provider/model failure and return `BLOCKED`.

After `nix develop`, the pinned CLI is available directly on platforms where OpenCodePolicy publishes a package:

```sh
opencode-policy validate
opencode-policy audit-consumer --profile global --consumer . --strict
```

## Updating policy

OpenCodePolicy revisions advance only through an explicit dependency update:

The recommended path is the manual **GitHub Actions → Update OpenCodePolicy → Run workflow** operation with **Branch = main**, or:

```sh
gh workflow run update-opencode-policy.yml \
  --repo upiscium/dotnix \
  --ref main
```

This workflow runs only through an explicit `workflow_dispatch`; it has no schedule and never updates policy from push or pull-request events. It validates lock hygiene and the strict `global` profile before creating a Draft pull request.

For a local update:

```sh
nix flake update opencodePolicy
nix flake check --no-update-lock-file
opencode-policy audit-consumer --profile global --consumer . --strict
```

Review the root `flake.lock` diff before merging. OpenCodePolicy `main` moving does not change dotnix until the checked-in lock is deliberately updated. Host-local lockfiles must not be updated as part of this workflow.
