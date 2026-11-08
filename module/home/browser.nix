{
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [ "--enable-wayland-ime" "--ozone-platform=wayland" ];
  };

  # Unpacked Chrome extension: Enter = newline, Ctrl/Cmd+Enter = send on claude.ai.
  # recursive = true keeps the directory itself a real path, so Chrome's
  # symlink-resolving "Load unpacked" stores a stable path instead of a
  # /nix/store path that changes on every rebuild.
  # One-time manual step: chrome://extensions -> Developer mode ->
  # "Load unpacked" -> ~/.local/share/chrome-extensions/claude-enter-remap
  home.file.".local/share/chrome-extensions/claude-enter-remap" = {
    source = ./browser/claude-enter-remap;
    recursive = true;
  };
}
