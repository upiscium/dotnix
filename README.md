# dotnix

## Repository structure

- The root `flake.nix` owns repository-level policy validation, minimal development tooling, and CI only.
- Host directories such as `Adam/`, `Caspar/`, `Eve/`, `Michael/`, and `Ramiel/` retain authority for their NixOS and Home Manager configurations, inputs, and lockfiles.
- `config.d/opencode/` remains the deployed global OpenCode implementation. Home Manager deployment continues to be owned by `common/home/terminal.nix`.

The root flake does not aggregate hosts, expose `nixosConfigurations` or `homeConfigurations`, consolidate host inputs, or participate in deployment.

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

```sh
nix flake update opencodePolicy
nix flake check --no-update-lock-file
opencode-policy audit-consumer --profile global --consumer . --strict
```

Review the root `flake.lock` diff before merging. OpenCodePolicy `main` moving does not change dotnix until the checked-in lock is deliberately updated. Host-local lockfiles must not be updated as part of this workflow.
