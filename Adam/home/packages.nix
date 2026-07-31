{ pkgs, ... }: {
  home.packages = with pkgs; [
    claude-code
    opencode
    dig
    swappy
    # termpdfpy
    typst
    unzip
    wayland-scanner
  ];
}
