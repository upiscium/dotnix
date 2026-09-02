{ lib, pkgs, ... }:
let
  waybar = pkgs.callPackage ./default.nix { };
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.packages = [ waybar ];
}
