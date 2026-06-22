{ ... }: {
  imports = [
    ../../common/home
    ./packages.nix
  ];

  home.file.".config/uwsm/env".text = ''
    export GMB_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    # export LIBVA_DRIVER_NAME=nvidia
  '';
}
