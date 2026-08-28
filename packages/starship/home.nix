{ pkgs, ... }:
let
  starship = pkgs.callPackage ./default.nix { };
in
{
  programs.starship = {
    enable = true;
    package = starship;
    configPath = "${./config/starship.toml}";
  };
}
