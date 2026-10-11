{ pkgs, ... }:
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
in
{
  imports = [ ../../module/home/hyprland.nix ];

  # Only the additional tools used by the shared screenshot/recording bindings.
  home.packages = with pkgs; [ screenshot slurp gpu-screen-recorder gpu-screen-recorder-gtk ];
}
