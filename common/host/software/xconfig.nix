{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      # xdg-desktop-portal-hyprland
    ];
    config = {
      common = {
        default = [ "gtk3" ];
      };
    };
  };

  services.xserver.enable = true;
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

}
