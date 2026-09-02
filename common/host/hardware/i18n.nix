{ pkgs, ... }: {
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    # Use Japanese glyph variants when an application cannot determine the
    # language of CJK text (notably Chromium and other browsers).
    LC_CTYPE = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    skktools
    mozcdic-ut-skk-jisyo
    ibus
  ];

  environment.variables = {
    # GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    GLFW_IM_MODULE = "fcitx";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-skk
    ];
  };

  fonts = {
    packages = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.caskaydia-cove
      source-sans
      source-serif
      source-han-sans
      source-han-serif
      # symbol
      # wingdings
      # wingdings-2
      # wingdings-3
      # webdings
      # mt-extra
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif CJK JP" "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans CJK JP" "Noto Color Emoji" ];
        monospace = [ "Caskaydia Cove Nerd Font" "Noto Sans Mono CJK JP" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
