set shell := ["bash", "-euo", "pipefail", "-c"]

# Show available dotnix packages and apps.
default:
    @just --list

# Show flake outputs for every supported platform.
list:
    nix flake show --all-systems --no-write-lock-file

# Evaluate the complete portable package contract without building packages.
check:
    nix flake check --all-systems --no-build --no-update-lock-file

# Build one local package output.
build package:
    nix build ".#{{package}}" -L --no-update-lock-file

# Run one local package output without installing it.
run package:
    nix run ".#{{package}}"

# Install one local package into the current Nix profile.
install package:
    nix profile install ".#{{package}}"

# Install a package directly from the public dotnix GitHub flake.
install-remote package:
    nix profile install "github:upiscium/dotnix#{{package}}"

# Remove profile entries matching the supplied Nix profile selector/regex.
remove selector:
    nix profile remove "{{selector}}"

# Show the current Nix profile.
profile:
    nix profile list
