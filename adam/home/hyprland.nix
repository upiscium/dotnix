{ inputs, lib, pkgs, ... }:
let
  screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = with pkgs; [ coreutils grim slurp wl-clipboard libnotify ];
    text = ''
      case "''${1:-}" in
        whole) geometry=() ;;
        selection)
          region=$(slurp) || exit 0
          [ -n "$region" ] || exit 0
          geometry=(-g "$region")
          ;;
        *)
          echo "Usage: hypr-screenshot whole|selection" >&2
          exit 1
          ;;
      esac

      directory="$HOME/Pictures/screenshots"
      mkdir -p "$directory"
      image="$directory/screenshot_$(date +%Y-%m-%d_%H-%M-%S_%N).png"
      grim -c "''${geometry[@]}" "$image"
      wl-copy --type image/png < "$image"
      notify-send "Screenshot copied to clipboard."
    '';
  };

  adamHyprlandSessionReady = pkgs.writeShellApplication {
    name = "adam-hyprland-session-ready";
    runtimeInputs = [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
      pkgs.uwsm
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      if ! timeout --kill-after=1s 3s hyprctl monitors -j | jq -e 'any(.[]; .name == "SUNSHINE")' >/dev/null; then
        if ! timeout --kill-after=1s 3s hyprctl output create headless SUNSHINE; then
          echo "Failed to create the SUNSHINE headless output." >&2
        fi
      fi

      exec uwsm finalize
    '';
  };
in
{
  imports = [ ../../module/home/hyprland.nix ];

  home.file.".config/uwsm/env".text = lib.mkAfter ''
    export AQ_DRM_DEVICES=/dev/dri/adam-nvidia
  '';

  # Keep the session helper and tools used by the shared screenshot/recording bindings.
  home.packages = with pkgs; [
    screenshot
    slurp
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    adamHyprlandSessionReady
  ];
}
