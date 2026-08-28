{ lib, pkgs, ... }:
let
  starship = pkgs.callPackage ./default.nix { };
in
{
  programs.starship = {
    enable = true;
    package = starship;
  };

  # Home Manager's programs.starship.configPath is a home.file target and
  # therefore cannot point directly into the Nix store. Keep that target
  # unused and make the packaged immutable config authoritative through the
  # session environment instead. The wrapper enforces the same path when the
  # package is used outside Home Manager.
  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce "${./config/starship.toml}";
}
