{
  pkgs,
  ...
}:{
  # Fonts
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
  ];
  fonts.fontconfig.enable = true;
}
