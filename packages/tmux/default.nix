{
  lib,
  symlinkJoin,
  makeWrapper,
  tmux,
  coreutils,
}:
symlinkJoin {
  name = "tmux-upiscium";

  paths = [ tmux ];
  nativeBuildInputs = [ makeWrapper ];

  # Always start tmux with the immutable configuration shipped by this
  # package. Supplying -f on every invocation is safe: tmux only consumes the
  # configuration when a new server is created, while clients attach to the
  # already-running server as usual.
  postBuild = ''
    wrapProgram "$out/bin/tmux" \
      --add-flags "-f ${./config/tmux.conf}" \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}
  '';

  meta = tmux.meta // {
    description = "upiscium's configured tmux environment";
  };
}
