{ pkgs, ... }: {
  home.packages = with pkgs; [
    # antigravity
    bambu-studio
    blender
    claude-code
    droidcam
    # discord
    vesktop
    gdlauncher-carbon
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    jetbrains-toolbox
    # modrinth-app
    # krita
    moonlight-qt
    obsidian
    obs-studio
    obs-studio-plugins.droidcam-obs
    # onlyoffice-desktopeditors
    wpsoffice
    libreoffice
    parsec-bin
    prismlauncher
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
