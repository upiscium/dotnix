{ pkgs, ... }: {
  home.file.".ssh" = {
    source = ../../config.d/.ssh;
    recursive = true;
  };
}
