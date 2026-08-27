{ ... }: {
  imports = [
    ./git.nix
    # ./gpg.nix
    ../../packages/neovim/home.nix
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

