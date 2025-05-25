{
  pkgs,
  ...
}:
{
  # Fonts
  home.packages = with pkgs; [
    nerd-fonts.sauce-code-pro
    corefonts
    liberation_ttf
    noto-fonts
    dejavu_fonts
  ];
  fonts.fontconfig.enable = true;
}
