{ lib, pkgs, ... }:
{
  # Both Claude CLI account profiles use the same editor/keybindings preferences.
  # Merge into writable JSON: ~/.claude/settings.json already contains
  # user-owned preferences and must not be replaced with a Nix store symlink.
  # Do not set CLAUDE_CONFIG_DIR here; zsh.nix handles company/personal routing.
  home.activation.claudeInputPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.bash}/bin/bash ${../../common/home/claude/apply-preferences.sh} ${pkgs.jq}/bin/jq "$HOME/.claude" "$HOME/.claude-work"
  '';

  # Multi-model setup (Opus plan / Sonnet implement / Haiku research): user-level
  # subagents, skills, a read-only git hook, subagent limits in settings.json
  # `.env`, and a marked block in CLAUDE.md. The agents also include
  # local-delegate, the dispatch window to the Opencode local workers on
  # TSUMGI (processing-only delegation; worker authority stays in
  # packages/opencode). Personal profile only; the company profile
  # (~/.claude-work) is intentionally not touched.
  home.activation.claudeMultiModel = lib.hm.dag.entryAfter [ "claudeInputPreferences" ] ''
    run env PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.gnused pkgs.diffutils ]}:$PATH" ${pkgs.bash}/bin/bash ${../../common/home/claude/apply-multimodel.sh} ${pkgs.jq}/bin/jq "$HOME/.claude" ${../../common/home/claude/multimodel}
  '';
}
