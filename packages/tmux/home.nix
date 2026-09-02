{ pkgs, ... }:
let
  tmux = pkgs.callPackage ./default.nix { };
in
{
  home.packages = [ tmux ];
}
