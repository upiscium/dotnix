{ pkgs, ... }: {
  home.packages = with pkgs; [
    antigravity
    bambu-studio
    blender
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
    # onlyoffice-desktopeditors
    wpsoffice
    libreoffice
    opencode
    parsec-bin
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
