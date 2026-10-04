{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [
    nvitop
    nvtopPackages.full
    # nvidia-container-toolkit
  ];

  # virtualisation.docker.rootless.daemon.settings.features.cdi = true;
  # hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
