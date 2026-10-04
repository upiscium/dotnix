{ pkgs, ... }:
let
  codex = pkgs.callPackage ./default.nix { };
in
{
  home.packages = [ codex ];
}
