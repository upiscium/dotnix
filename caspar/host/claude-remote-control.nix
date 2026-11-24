let
  home = "/home/upiscium";
in
{
  imports = [ ../../module/host/claude-remote-control.nix ];

  # Home is omitted: its trust prompt reappears on every start.
  claudeRemoteControl.dirs = {
    Programs = "${home}/Documents/Programs";
    Research = "${home}/Documents/Research";
  };
}
