{ pkgs, hostname, ... }: {
  imports = [
    ../../packages/waybar/home.nix
  ];

  home.packages = with pkgs; [
    brightnessctl
    grim
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    libnotify
    nemo-with-extensions
    networkmanagerapplet
    playerctl
    swaynotificationcenter
    wofi
    wl-clipboard
    wlogout
  ];

  home.file.".config/hypr/hypridle.conf" = {
    source = ./hyprland/hypridle.conf;
  };

  home.file.".config/hypr/hyprland.lua" = {
    source = ./hyprland/hyprland.lua;
  };

  home.file.".config/hypr/hyprlock.conf" = {
    source = ./hyprland/hyprlock.conf;
  };

  home.file.".config/hypr/hyprpaper.conf" = {
    source = ./hyprland/hyprpaper.conf;
  };

  home.file.".config/hypr/platform.lua" = {
    source = ./hyprland/platforms/${hostname}.lua;
  };

  home.file.".config/swaync" = {
    source = ./hyprland/swaync;
    recursive = true;
  };

  home.file.".config/wlogout" = {
    source = ./hyprland/wlogout;
    recursive = true;
  };

  home.file.".config/wofi" = {
    source = ./hyprland/wofi;
    recursive = true;
  };
}
