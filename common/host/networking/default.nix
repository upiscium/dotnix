{ ... }: {
  imports = [
    ./network.nix
    ./ssh.nix
  ];

  programs.wireshark.enable = true;
}
