{ ... }: {
  imports = [
    ../../common/home
    ../../module/home/claude.nix
    ../../module/home/uwsm-nvidia.nix
    ./hyprland.nix
    ./packages.nix
  ];
}
