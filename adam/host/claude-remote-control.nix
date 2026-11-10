{ pkgs, lib, ... }:

# Claude Code Remote Control: one `claude remote-control --spawn worktree`
# server per repository, kept alive by a loop inside a dedicated tmux socket.
# Runs as upiscium with the personal Claude account (~/.claude-personal).
# Each repository must have been started once by hand so that the Remote
# Control, trust and spawn-mode prompts are already answered.
let
  user = "upiscium";
  home = "/home/${user}";
  programs = "${home}/Documents/Programs";

  # Service name suffix -> repository checkout (must be a primary clone, not a
  # git worktree: `.git` has to be a directory).
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

  claude = pkgs.claude-code;

  # Tools the spawned sessions rely on, pinned so the service does not depend
  # on the Home Manager profile alone.
  toolPath = lib.makeBinPath (with pkgs; [ git gh ripgrep fd jq coreutils ]);

  loop = pkgs.writeShellScript "claude-rc-loop" ''
    export PATH=${toolPath}:${home}/.nix-profile/bin:/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin
    export CLAUDE_CONFIG_DIR=${home}/.claude-personal
    unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL \
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC DISABLE_GROWTHBOOK
    # No pre-created session: it would run in the main checkout instead of an
    # isolated worktree.
    while true; do
      ${claude}/bin/claude remote-control --spawn worktree --no-create-session-in-dir --name "$1"
      sleep 15
    done
  '';

  mkSvc = name: dir: lib.nameValuePair "claude-rc-${lib.toLower name}" {
    description = "Claude Code Remote Control (${name})";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "forking";
      User = user;
      WorkingDirectory = dir;
      ExecStart = "${pkgs.tmux}/bin/tmux -L rc-${name} new-session -d -s rc ${loop} ${name}";
      ExecStop = "${pkgs.tmux}/bin/tmux -L rc-${name} kill-server";
      # upiscium has passwordless sudo; keep remote sessions from using it.
      NoNewPrivileges = true;
    };
  };
in
{
  systemd.services = lib.mapAttrs' mkSvc repos;
}
