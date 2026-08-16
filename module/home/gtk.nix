{ pkgs, ... }:
{
  gtk.enable = true;
  gtk.theme.package = pkgs.adw-gtk3;
  gtk.theme.name = "adw-gtk3";
  gtk.gtk4.theme.package = pkgs.adw-gtk3;
  gtk.gtk4.theme.name = "adw-gtk3";
  gtk.iconTheme.package = pkgs.tela-icon-theme;
  gtk.iconTheme.name = "Tela";
  # gtk.cursorTheme.package = pkgs.volantes-cursors;
  # gtk.cursorTheme.name = "Volantes";

  qt.enable = true;
  qt.platformTheme.name = "gtk3";
  qt.style.name = "adwaita";
}
