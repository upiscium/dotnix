{ pkgs, ... }:
let
  neovim = pkgs.callPackage ./default.nix { inherit pkgs; };
in
{
  home.packages = [ neovim ];
}
