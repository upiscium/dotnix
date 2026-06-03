{ inputs, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    kanshi
  ];

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/start-hyprland";
      };
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
    # withUWSM = false;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --user-menu --cmd start-hyprland";
        user = "greeter";
      };
    };
  };

  services.displayManager = {
    sddm.enable = false;
    gdm.enable = false;
  };

  # services.displayManager.sddm = {
  #   enable = false;
  #   wayland.enable = true;
  # };

  # services.displayManager.defaultSession = "hyprland";

  # services.displayManager.gdm = {
  #   enable = true;
  # };
}
