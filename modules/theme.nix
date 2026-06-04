{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    apple-cursor
    andromeda-gtk-theme
    zafiro-icons
    adwaita-icon-theme
    gnome-themes-extra
  ];

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
    theme = {
      name = "Andromeda";
      package = pkgs.andromeda-gtk-theme;
    };
    iconTheme = {
      name = "Zafiro-icons-Dark";
      package = pkgs.zafiro-icons;
    };
    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Andromeda
    gtk-icon-theme-name=Zafiro-icons-Dark
    gtk-cursor-theme-name=Apple
    gtk-cursor-theme-size=24
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Andromeda
    gtk-icon-theme-name=Zafiro-icons-Dark
    gtk-cursor-theme-name=macOS
    gtk-cursor-theme-size=24
  '';

  home.sessionVariables = {
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "24";
  };
}
