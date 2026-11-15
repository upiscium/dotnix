{ pkgs }:
let
  inherit (pkgs) lib;
  # Exercise the real wrapper without building or contacting OpenCode itself.
  runtime = (pkgs.writeShellScriptBin "opencode" ''
    printf '%s\0' "$@" > "''${OPENCODE_TEST_ARGS:?}"
  '').overrideAttrs (_: { version = "2.0.0"; });
  package = pkgs.callPackage ../../packages/opencode { opencode = runtime; };
  closure = pkgs.closureInfo { rootPaths = [ package ]; };
  configPath = toString package.config;
in
pkgs.runCommand "opencode-launcher-tests" {
  nativeBuildInputs = [ pkgs.diffutils pkgs.findutils pkgs.gnugrep ];
} ''
  export HOME="$TMPDIR/home"
  export XDG_CONFIG_HOME="$TMPDIR/xdg with spaces"
  export OPENCODE_TEST_ARGS="$TMPDIR/actual-args"
  mkdir -p "$HOME"

  # A sandbox exposes only runtime dependencies, not the evaluation checkout.
  # The old toString ./config reference fails here with `cp: cannot stat`.
  ${package}/bin/opencode --version "two words" "" '*'
  printf '%s\0' --version "two words" "" '*' > "$TMPDIR/expected-args"
  cmp "$TMPDIR/expected-args" "$OPENCODE_TEST_ARGS"

  # Also catch the missing dependency when a builder has sandboxing disabled.
  grep -Fx -- ${lib.escapeShellArg configPath} ${closure}/store-paths

  source_config=${lib.escapeShellArg configPath}
  printf '%s\n' ${lib.escapeShellArgs package.managedEntries} > "$TMPDIR/expected-manifest"
  check_config() {
    local config_dir="$1"
    for entry in ${lib.escapeShellArgs package.managedEntries}; do
      diff -r -- "$source_config/$entry" "$config_dir/$entry"
    done
    cmp "$TMPDIR/expected-manifest" "$config_dir/.dotnix-managed-entries"
    test -z "$(find "$config_dir" -type f ! -perm -u+w -print -quit)"
    test ! -e "$config_dir/.dotnix-sync.lock"
  }

  check_config "$XDG_CONFIG_HOME/opencode"
  test ! -e "$HOME/.config/opencode"

  unset XDG_CONFIG_HOME
  ${package}/bin/opencode --help
  printf '%s\0' --help > "$TMPDIR/expected-args"
  cmp "$TMPDIR/expected-args" "$OPENCODE_TEST_ARGS"
  check_config "$HOME/.config/opencode"

  touch "$out"
''
