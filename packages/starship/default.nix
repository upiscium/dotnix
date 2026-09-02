{
  symlinkJoin,
  makeWrapper,
  starship,
}:
symlinkJoin {
  name = "starship-upiscium";

  paths = [ starship ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    rm -f "$out/bin/starship"
    makeWrapper "${starship}/bin/starship" "$out/bin/starship" \
      --set STARSHIP_CONFIG "${./config/starship.toml}"
  '';

  meta = starship.meta // {
    description = "upiscium's configured Starship prompt";
    outputsToInstall = [ "out" ];
  };
}
