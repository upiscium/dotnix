{
  symlinkJoin,
  writeShellScriptBin,
  waybar,
}:
let
  mkLauncher = name: config:
    writeShellScriptBin name ''
      exec ${waybar}/bin/waybar \
        --config "${config}" \
        --style "${./config/style.css}" \
        "$@"
    '';

  top = mkLauncher "waybar-top" ./config/top.jsonc;
  bottom = mkLauncher "waybar-bottom" ./config/bottom.jsonc;
in
symlinkJoin {
  name = "waybar-upiscium";

  paths = [
    waybar
    top
    bottom
  ];

  meta = waybar.meta // {
    description = "upiscium's configured Waybar environment";
    mainProgram = "waybar-top";
    outputsToInstall = [ "out" ];
  };
}
