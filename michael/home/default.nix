{ ... }: {
  imports = [
    ../../common/home

    ../../module/home/browser.nix
    ../../module/home/gtk.nix
    ../../module/home/hyprland.nix
    ../../module/home/uwsm-nvidia.nix

    ./moonlight.nix
    ./packages.nix
  ];
}
