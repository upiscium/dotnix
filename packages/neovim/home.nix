{ pkgs, ... }:
let
  neovim = pkgs.callPackage ./default.nix { };
in
{
  home.packages = [ neovim ];
}
