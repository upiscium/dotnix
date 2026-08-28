# dotnix

## Repository structure

- The root `flake.nix` owns reusable package outputs, repository-level policy validation, minimal development tooling, and CI.
- Host directories such as `Adam/`, `Caspar/`, `Eve/`, `Michael/`, and `Ramiel/` retain authority for their NixOS and Home Manager configurations, inputs, and lockfiles.
- `packages/` contains self-contained application artifacts that can be consumed by host-local NixOS/Home Manager configurations or through the root flake.
- `config.d/opencode/` remains the deployed global OpenCode implementation. Home Manager deployment continues to be owned by `common/home/terminal.nix`.

The root flake does not aggregate hosts, expose `nixosConfigurations` or `homeConfigurations`, consolidate host inputs, or own deployment. Its package outputs are reusable artifacts only; host-local flakes remain the deployment authority.

## Neovim package

The configured Neovim environment is owned by `packages/neovim/`:

- `default.nix` builds the standalone wrapped Neovim derivation.
- `config/` owns the Lua configuration previously stored under `config.d/nvim/`.
- `home.nix` is the thin Home Manager integration used by `common/home/`.

The package includes the Neovim providers plus the LSP servers, formatters, compilers, and command-line tools that were previously supplied by `common/home/neovim.nix`. It can be built or run independently:

```sh
nix build .#neovim
nix run .#neovim
```

The existing `lazy.nvim` bootstrap remains unchanged for this first migration, so Neovim plugins are still acquired at runtime. The standalone package therefore makes the editor, configuration, providers, LSPs, formatters, and supporting executables reproducible, but plugin acquisition is not yet fully Nix-managed.

## OpenCodePolicy

dotnix pins [`upiscium/OpenCodePolicy`](https://github.com/upiscium/OpenCodePolicy) through the root `flake.lock` and explicitly conforms to the `global` profile. OpenCodePolicy owns the shared policy and compatibility contract; dotnix remains the global OpenCode implementation owner.

The dependency is validation-only. It does not generate or materialize agents, prompts, commands, skills, provider settings, or any other file under `config.d/opencode/`.

The `global` profile enforces the fixed Sol/Terra/Luna role assignments used by dotnix. It does not permit Spark, fallback agents, model substitution, or alternate-model retries; an unavailable configured model must report the exact provider/model failure and return `BLOCKED`.

After `nix develop`, the pinned CLI is available directly:

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
