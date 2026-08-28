{ ... }: {
  imports = [
    ./clang.nix
    ./git.nix
    # ./gpg.nix
    ../../packages/kitty/home.nix
    ../../packages/neovim/home.nix
    ../../packages/tmux/home.nix
    ./packages.nix
    ./ssh.nix
    ./terminal.nix
    ./zsh.nix
  ];

  # home = rec {
  #   username = "upiscium";
  #   homeDirectory = "/home/${username}";
  #   stateVersion = "25.11";
  # };

  programs.home-manager.enable = true;
}

