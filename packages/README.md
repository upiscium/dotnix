# Portable package authoring

Each custom portable application lives in its own directory under `packages/`.
The root flake discovers package directories automatically; adding a package must not require editing `flake.nix`.

## Minimal package

Create:

```text
packages/
└── example/
    └── default.nix
```

`default.nix` must evaluate to a function suitable for `pkgs.callPackage`:

```nix
{ writeShellApplication }:
writeShellApplication {
  name = "example";
  text = ''
    echo example
  '';
}
```

The package is then exposed automatically as:

```text
packages.<system>.example
checks.<system>.example-package
```

and becomes usable through the existing interfaces:

```sh
nix build .#example
nix run .#example
just build example
just install example
nix profile add github:upiscium/dotnix#example
```

## Access to the complete package set

Normal `callPackage` arguments should be preferred. If a package genuinely needs the complete Nixpkgs package set, it may explicitly accept `pkgs`:

```nix
{ lib, pkgs, ... }:
# ...
```

The registry detects that argument and supplies the current system's `pkgs` value.

## Platform restrictions

By default a package is published on every platform in the root portable contract:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

If a package supports only a subset, add `systems.nix` beside `default.nix`:

```nix
[
  "x86_64-linux"
  "aarch64-linux"
]
```

The registry validates that `systems.nix` is a duplicate-free list containing only systems from the root contract. Unsupported systems are omitted from both `packages` and `checks`, so a Linux-only package does not break Darwin evaluation.

## Naming

Package directory names must match:

```text
^[a-z0-9][a-z0-9._-]*$
```

`just` is reserved for the root bootstrap utility and cannot be used as a custom package directory name.

## Responsibility boundary

A portable package must be independently useful outside host-local NixOS/Home Manager configurations. Host integration belongs in Home Manager/NixOS modules; machine-specific state and policy do not belong in the portable derivation.
