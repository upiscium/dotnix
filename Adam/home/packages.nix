{ pkgs, ... }: {
  home.packages = with pkgs; [
    claude-code
    dig
    swappy
    # termpdfpy
    typst
    unzip
    wayland-scanner
  ];
}
