{
  pkgs,
  ...
}:
{
  # Fonts
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
    corefonts
    liberation_ttf
    noto-fonts
    dejavu_fonts
  ];
  fonts.fontconfig.enable = true;
}
