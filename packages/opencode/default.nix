{
  lib,
  symlinkJoin,
  writeShellApplication,
  coreutils,
  opencode,
}:
let
  configSource = ./config;
  managedEntries = lib.attrNames (builtins.readDir configSource);
  managedManifest = builtins.toFile "dotnix-opencode-managed-entries" (
    lib.concatStringsSep "\n" managedEntries + "\n"
  );

  launcher = writeShellApplication {
    name = "opencode";
    runtimeInputs = [ coreutils ];
    text = ''
      set -euo pipefail

      source_config=${lib.escapeShellArg (toString configSource)}
      source_manifest=${lib.escapeShellArg (toString managedManifest)}

      if [ -n "''${XDG_CONFIG_HOME:-}" ]; then
        config_home="$XDG_CONFIG_HOME"
      else
        : "''${HOME:?HOME must be set when XDG_CONFIG_HOME is unset}"
        config_home="$HOME/.config"
      fi
      config_dir="$config_home/opencode"

      if [ -L "$config_dir" ]; then
        echo "dotnix opencode: refusing to replace symlinked config directory: $config_dir" >&2
        exit 1
      fi
      mkdir -p "$config_dir"

      lock_dir="$config_dir/.dotnix-sync.lock"
      acquire_lock() {
        while ! mkdir "$lock_dir" 2>/dev/null; do
          if [ -r "$lock_dir/pid" ]; then
            lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
            case "$lock_pid" in
              *[!0-9]*) ;;
              *)
                if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
                  rm -rf -- "$lock_dir"
                  continue
                fi
                ;;
            esac
          fi
          sleep 0.05
        done
        printf '%s\n' "$$" > "$lock_dir/pid"
      }

      release_lock() {
        rm -rf -- "$lock_dir"
      }

      validate_entry() {
        entry="$1"
        if [ -z "$entry" ] || [ "$entry" = "." ] || [ "$entry" = ".." ]; then
          echo "dotnix opencode: invalid managed config entry: $entry" >&2
          exit 1
        fi
        case "$entry" in
          */*|.dotnix-*)
            echo "dotnix opencode: invalid managed config entry: $entry" >&2
            exit 1
            ;;
        esac
      }

      acquire_lock
      trap release_lock EXIT INT TERM HUP

      runtime_manifest="$config_dir/.dotnix-managed-entries"
      if [ -f "$runtime_manifest" ]; then
        while IFS= read -r entry; do
          [ -n "$entry" ] || continue
          validate_entry "$entry"
          rm -rf -- "$config_dir/$entry"
        done < "$runtime_manifest"
      fi

      while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        validate_entry "$entry"
        rm -rf -- "$config_dir/$entry"
        cp -R -- "$source_config/$entry" "$config_dir/$entry"
        chmod -R u+rwX -- "$config_dir/$entry"
      done < "$source_manifest"

      manifest_tmp="$config_dir/.dotnix-managed-entries.tmp.$$"
      cp -- "$source_manifest" "$manifest_tmp"
      chmod u+rw -- "$manifest_tmp"
      mv -f -- "$manifest_tmp" "$runtime_manifest"

      release_lock
      trap - EXIT INT TERM HUP

      exec ${opencode}/bin/opencode "$@"
    '';
  };
in
symlinkJoin {
  name = "opencode-upiscium";

  paths = [ opencode ];

  postBuild = ''
    rm -f "$out/bin/opencode"
    ln -s "${launcher}/bin/opencode" "$out/bin/opencode"
  '';

  passthru = (opencode.passthru or { }) // {
    config = configSource;
    inherit managedEntries;
  };

  meta = opencode.meta // {
    description = "upiscium's configured OpenCode environment";
    outputsToInstall = [ "out" ];
  };
}
