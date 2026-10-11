{ ... }: {
  imports = [
    ../../common/home
    ../../module/home/uwsm-nvidia.nix
    ./hyprland.nix
    ./packages.nix
  ];
}
