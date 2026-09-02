{ pkgs, ... }:
let
  opencode = pkgs.callPackage ./default.nix { };
in
{
  home.packages = [ opencode ];
}
