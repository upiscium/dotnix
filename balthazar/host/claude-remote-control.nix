let
  home = "/home/upiscium";
  programs = "${home}/Documents/Programs";
in
{
  imports = [ ../../module/host/claude-remote-control.nix ];

  claudeRemoteControl = {
    repos = {
      ObsidianAutomation = "${programs}/ObsidianAutomation";
      ObsidianCore = "${programs}/ObsidianCore";
      KASANE = "${programs}/KASANE";
      MUSUBI = "${programs}/MUSUBI";
      KUMIKI = "${programs}/KUMIKI";
      TSUMGI = "${programs}/TSUMGI";
      Terreate = "${programs}/Terreate";
      PROJECT-SUZKA = "${programs}/PROJECT-SUZKA";
      RITSU = "${programs}/RITSU";
    };
    dirs = {
      Programs = programs;
      Research = "${home}/Documents/Research";
      Home = home;
    };
  };
}
