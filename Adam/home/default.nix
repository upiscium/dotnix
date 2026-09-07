{ ... }: {
  imports = [
    ../../common/home
    ../../module/home/uwsm-nvidia.nix
    ./packages.nix
  ];
}
