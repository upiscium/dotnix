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

# Install one local package. Set DOTNIX_PROFILE to target an isolated profile.
install package:
    if [ -n "${DOTNIX_PROFILE:-}" ]; then nix profile install --profile "$DOTNIX_PROFILE" ".#{{package}}"; else nix profile install ".#{{package}}"; fi

# Install from the public dotnix GitHub flake. Honors DOTNIX_PROFILE.
install-remote package:
    if [ -n "${DOTNIX_PROFILE:-}" ]; then nix profile install --profile "$DOTNIX_PROFILE" "github:upiscium/dotnix#{{package}}"; else nix profile install "github:upiscium/dotnix#{{package}}"; fi

# Remove profile entries matching the supplied Nix profile selector/regex.
remove selector:
    if [ -n "${DOTNIX_PROFILE:-}" ]; then nix profile remove --profile "$DOTNIX_PROFILE" "{{selector}}"; else nix profile remove "{{selector}}"; fi

# Show the selected Nix profile.
profile:
    if [ -n "${DOTNIX_PROFILE:-}" ]; then nix profile list --profile "$DOTNIX_PROFILE"; else nix profile list; fi
