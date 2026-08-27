{ pkgs, ... }:
let
  neovim = pkgs.callPackage ./default.nix { };
in
{
  home.packages = [ neovim ];

  # These remain user-level integration files rather than part of the Neovim
  # derivation itself. The editor configuration is loaded directly from the
  # immutable package source under packages/neovim/config.
  home.file.".config/mcphub" = {
    source = ../../config.d/mcphub;
    recursive = true;
  };

  home.file.".clang-tidy".source = ../../config.d/clangd/.clang-tidy;
  # home.file.".config/clangd/config.yaml".source = ../../config.d/clangd/config.yaml;
}
