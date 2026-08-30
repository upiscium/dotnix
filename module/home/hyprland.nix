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
    source = ../../config.d/hypr/hypridle.conf;
  };

  home.file.".config/hypr/hyprland.lua" = {
    source = ../../config.d/hypr/hyprland.lua;
  };

  home.file.".config/hypr/hyprlock.conf" = {
    source = ../../config.d/hypr/hyprlock.conf;
  };

  home.file.".config/hypr/hyprpaper.conf" = {
    source = ../../config.d/hypr/hyprpaper.conf;
  };

  home.file.".config/hypr/platform.lua" = {
    source = ../../config.d/hypr/platforms/${hostname}.lua;
  };

  home.file.".config/swaync" = {
    source = ../../config.d/swaync;
    recursive = true;
  };

  home.file.".config/wlogout" = {
    source = ../../config.d/wlogout;
    recursive = true;
  };

  home.file.".config/wofi" = {
    source = ../../config.d/wofi;
    recursive = true;
  };
}
