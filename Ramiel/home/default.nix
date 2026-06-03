{ ... }: {
  imports = [
    ../../common/home

    ../../module/home/browser.nix
    ../../module/home/gtk.nix
    ../../module/home/hyprland.nix

    ./packages.nix
  ];
}
