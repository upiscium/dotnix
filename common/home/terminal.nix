{ ... }: {
  home.file.".config/opencode" = {
    source = ../../config.d/opencode;
    recursive = true;
  };
}
