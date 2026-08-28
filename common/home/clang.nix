{ ... }: {
  # User-level C/C++ development policy. This is intentionally separate from
  # the Neovim package because clang-tidy also applies outside the editor.
  home.file.".clang-tidy".source = ../../config.d/clangd/.clang-tidy;

  # Keep the existing clangd config disabled for now. It hard-codes
  # ~/.nix-profile/bin/g++ and therefore does not satisfy the standalone
  # package boundary used by packages/neovim.
  # home.file.".config/clangd/config.yaml".source = ../../config.d/clangd/config.yaml;
}
