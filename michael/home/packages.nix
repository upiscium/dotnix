{ pkgs, ... }: {
  home.packages = with pkgs; [
    # antigravity
    # bambu-studio
    # blender
    claude-code
    droidcam
    vesktop # discord
    firefox
    # gdlauncher-carbon
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    # jetbrains-toolbox
    # modrinth-app
    # krita
    moonlight-qt
    obsidian
    obs-studio
    obs-studio-plugins.droidcam-obs
    kdePackages.okular
    # onlyoffice-desktopeditors
    wpsoffice
    libreoffice
    parsec-bin
    (prismlauncher.overrideAttrs (old: {
      # Match nvidia-offload for this hybrid-GPU host without forcing other apps.
      # Do not inherit the session-wide GBM backend into Minecraft.
      qtWrapperArgs = old.qtWrapperArgs ++ [
        "--unset GBM_BACKEND"
        "--set __NV_PRIME_RENDER_OFFLOAD 1"
        "--set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0"
        "--set __GLX_VENDOR_LIBRARY_NAME nvidia"
        "--set __VK_LAYER_NV_optimus NVIDIA_only"
      ];
    }))
    slack
    unityhub
    # teams-for-linux
    vlc
    wireshark
    zoom-us

    dig
    grim
    jdk17
    power-profiles-daemon
    slurp
    swappy
    # termpdfpy
    typst
    unzip
    wayland-scanner
    yt-dlp
  ];
}
