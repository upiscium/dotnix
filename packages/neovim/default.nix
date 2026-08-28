{
  lib,
  pkgs,
  wrapNeovimUnstable,
  neovim-unwrapped,
}:
let
  clangTools = if pkgs.stdenv.isLinux then
    pkgs.clang-tools.override {
      enableLibcxx = true;
    }
  else
    pkgs.clang-tools;

  runtimeDeps = [
    pkgs.deno
    clangTools
    pkgs.gnumake
    pkgs.nodejs
    pkgs.tree-sitter
    pkgs.imagemagick
    pkgs.git
    pkgs.uv
    pkgs.zsh

    pkgs.bash-language-server
    pkgs.cmake-language-server
    pkgs.dockerfile-language-server
    pkgs.efm-langserver
    pkgs.lua-language-server
    pkgs.nil
    pkgs.nixpkgs-fmt
    pkgs.nixpkgs-lint
    pkgs.vscode-langservers-extracted
    pkgs.typescript-language-server
    pkgs.omnisharp-roslyn
    pkgs.basedpyright
    pkgs.python312Packages.debugpy
    pkgs.ruff
    pkgs.rust-analyzer
    pkgs.glsl_analyzer
    pkgs.shellcheck
    pkgs.shader-slang
    pkgs.stylua
    pkgs.taplo
    pkgs.tinymist
    pkgs.typstyle
    pkgs.vim-language-server
    pkgs.yaml-language-server
    pkgs.yamlfmt
    pkgs.yamllint
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.gcc
    pkgs.glibc
  ];
in
wrapNeovimUnstable neovim-unwrapped {
  extraName = "-upiscium";

  viAlias = true;
  withRuby = true;
  withPython3 = true;

  extraLuaPackages = ps:
    lib.optional (builtins.hasAttr "magick" ps) ps.magick
    ++ lib.optional (builtins.hasAttr "tiktoken_core" ps) ps.tiktoken_core;

  # Keep the existing Lua configuration authoritative while making the
  # configured editor runnable directly from the derivation. lazy.nvim still
  # owns plugin acquisition for now; only the editor, providers, tools, LSPs,
  # formatters, and MCP server launcher dependencies are made reproducible by
  # this package.
  luaRcContent = ''
    vim.opt.runtimepath:prepend("${./config}")
    dofile("${./config}/init.lua")
  '';

  wrapperArgs = [
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath runtimeDeps)
  ];
}
