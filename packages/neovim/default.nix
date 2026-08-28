{
  lib,
  wrapNeovimUnstable,
  neovim-unwrapped,
  deno,
  clang-tools,
  gcc,
  glibc,
  gnumake,
  nodejs,
  tree-sitter,
  imagemagick,
  git,
  uv,
  bash-language-server,
  cmake-language-server,
  dockerfile-language-server,
  efm-langserver,
  lua-language-server,
  nil,
  nixpkgs-fmt,
  nixpkgs-lint,
  vscode-langservers-extracted,
  typescript-language-server,
  omnisharp-roslyn,
  basedpyright,
  python312Packages,
  ruff,
  rust-analyzer,
  glsl_analyzer,
  shellcheck,
  shader-slang,
  stylua,
  taplo,
  tinymist,
  typstyle,
  vim-language-server,
  yaml-language-server,
  yamlfmt,
  yamllint,
}:
let
  runtimeDeps = [
    deno
    (clang-tools.override {
      enableLibcxx = true;
    })
    gcc
    glibc
    gnumake
    nodejs
    tree-sitter
    imagemagick
    git
    uv

    bash-language-server
    cmake-language-server
    dockerfile-language-server
    efm-langserver
    lua-language-server
    nil
    nixpkgs-fmt
    nixpkgs-lint
    vscode-langservers-extracted
    typescript-language-server
    omnisharp-roslyn
    basedpyright
    python312Packages.debugpy
    ruff
    rust-analyzer
    glsl_analyzer
    shellcheck
    shader-slang
    stylua
    taplo
    tinymist
    typstyle
    vim-language-server
    yaml-language-server
    yamlfmt
    yamllint
  ];
in
wrapNeovimUnstable neovim-unwrapped {
  extraName = "-upiscium";

  viAlias = true;
  withRuby = true;
  withPython3 = true;

  extraLuaPackages = ps: [
    ps.magick
    ps.tiktoken_core
  ];

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
