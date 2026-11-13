{ pkgs, ... }:
let
  moonlight-adam = pkgs.writeShellApplication {
    name = "moonlight-adam";
    runtimeInputs = [ pkgs.moonlight-qt ];
    text = ''
      usage() {
        printf '%s\n' \
          'Usage: moonlight-adam [pair|--help]' \
          "" \
          'With no arguments, stream the logged-in Desktop on adam.' \
          'Use "moonlight-adam pair" to pair with adam and manually approve the PIN in Sunshine.'
      }

      case "''${1:-}" in
        "")
          if [ "$#" -ne 0 ]; then
            usage >&2
            exit 2
          fi
          exec moonlight stream --resolution 1920x1080 --fps 60 --bitrate 20000 --absolute-mouse --capture-system-keys fullscreen 10.255.255.61 Desktop
          ;;
        pair)
          if [ "$#" -ne 1 ]; then
            usage >&2
            exit 2
          fi
          exec moonlight pair 10.255.255.61
          ;;
        --help)
          if [ "$#" -ne 1 ]; then
            usage >&2
            exit 2
          fi
          usage
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [ moonlight-adam ];
}
