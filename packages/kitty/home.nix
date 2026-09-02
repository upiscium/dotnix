{ lib, pkgs, ... }:
let
  kitty = pkgs.callPackage ./default.nix { };
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.packages = [ kitty ];
}
