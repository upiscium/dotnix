# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./firewall.nix
      ./hardware.nix
      ./ipfix.nix
      ./ollama.nix
      # ./sunshine.nix

      ../../common/host
      ../../module/host/proxmox.nix
      # ../../module/NixOS/docker/rootful.nix
    ]
    ++ (with inputs.nixos-hardware.nixosModules; [
      common-cpu-amd
      # common-gpu-nvidia
      common-pc-ssd
    ]);

  # Bootloader.
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  nixpkgs.config = {
    allowUnfree = true;
    pulseaudio = true;
    nvidia.acceptLicense = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # prime = {
    #   reverseSync.enable = false;
    #   offload = {
    #     enable = true;
    #     enableOffloadCmd = true;
    #   };

    #   nvidiaBusId = "PCI:0:10:0";
    #   amdgpuBusId = "PCI:0:2:0";
    # };
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
    nvitop
  ];

  services.xserver.displayManager.lightdm.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
