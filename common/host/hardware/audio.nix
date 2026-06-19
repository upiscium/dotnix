# { ... }: {
#   services.pulseaudio.enable = false;
#   security.rtkit.enable = true;
#   services.pipewire = {
#     enable = true;
#     alsa.enable = true;
#     alsa.support32Bit = true;
#     jack.enable = true;
#     pulse.enable = true;
#     wireplumber.enable = true;
#   };

#   programs = {
#     noisetorch.enable = true;
#   };
# }
{ pkgs, ... }: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  hardware.alsa.enablePersistence = true;

  services.pipewire = {
    enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  programs.noisetorch.enable = true;

  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
  ];
}
