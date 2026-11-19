{ pkgs, ... }: {
  home.packages = with pkgs; [
    claude-code
    dig
    swappy
    unzip
  ];
}
