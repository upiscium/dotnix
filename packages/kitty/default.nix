{
  lib,
  symlinkJoin,
  makeWrapper,
  kitty,
}:
symlinkJoin {
  name = "kitty-upiscium";

  paths = [ kitty ];
  nativeBuildInputs = [ makeWrapper ];

  # Nixpkgs already wraps kitty for its runtime dependencies. Keep that
  # wrapper intact and add one outer launcher that redirects kitty's config
  # lookup to the immutable package-owned directory. Desktop entries invoke
  # `kitty`, so they resolve through this launcher as well.
  postBuild = ''
    rm -f "$out/bin/kitty"
    makeWrapper "${kitty}/bin/kitty" "$out/bin/kitty" \
      --set KITTY_CONFIG_DIRECTORY "${./config}"
  '';

  meta = kitty.meta // {
    description = "upiscium's configured Kitty terminal environment";
    outputsToInstall = [ "out" ];
  };
}
