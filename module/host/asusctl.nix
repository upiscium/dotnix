{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    asusctl
  ];

  services.supergfxd.enable = false;
  services.asusd = {
    enable = true;
    # enableUserService = true;
  };
}
