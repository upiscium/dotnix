{ lib, pkgs, ... }:
{
  # Both Claude CLI account profiles use the same editor/keybindings preferences.
  # Merge into writable JSON: ~/.claude-personal/settings.json already contains
  # user-owned preferences and must not be replaced with a Nix store symlink.
  # Do not set CLAUDE_CONFIG_DIR here; zsh.nix handles company/personal routing.
  home.activation.claudeInputPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.bash}/bin/bash ${../../common/home/claude/apply-preferences.sh} ${pkgs.jq}/bin/jq "$HOME/.claude" "$HOME/.claude-personal"
  '';
}
