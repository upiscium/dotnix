{ pkgs, ... }: {
  home.packages = with pkgs; [
    kitty
  ];

  programs.kitty = {
    enable = true;
  };

  home.file.".config/kitty" = {
    source = ../../config.d/kitty;
    recursive = true;
  };

  home.file.".config/opencode" = {
    source = ../../config.d/opencode;
    recursive = true;
  };
}
