{
  home,
  ...
}:{
  programs.alacritty = {
    enable = true;
    settings = {
      import = ["~/.config/alacritty/kolor.toml"];
      window = {
        decorations = "none";
        opacity = 1;
        startup_mode = "maximized";
        dynamic_padding = true;
      };
      font = {
        size = 17;
        normal = {
          family = "SauceCodePro Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "SauceCodePro Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "SauceCodePro Nerd Font";
          style = "Italic";
        };
        bold_italic = {
          family = "SauceCodePro Nerd Font";
          style = "Bold Italic";
        };
      };
      selection = {
        save_to_clipboard = true;
      };
    };
  };
  home.file.".config/alacritty/kolor.toml" = {
    text = ''
      [colors]
      [colors.bright]
      black = "#4a4a4a"
      blue = "#7eaefd"
      cyan = "#6bc1d0"
      green = "#7db37d"
      magenta = "#c18fcb"
      red = "#cc896d"
      white = "#c6c6c6"
      yellow = "#d96e8a"

      [colors.normal]
      black = "#242322"
      blue = "#8787af"
      cyan = "#4c8ea1"
      green = "#6c7e55"
      magenta = "#956d9d"
      red = "#9e5641"
      white = "#c6c6c6"
      yellow = "#dbc570"

      [colors.primary]
      background = "#2e2d2b"
      foreground = "#c6c6c6"
    '';
  };
  home.file.".config/alacritty/gnome-light.toml" = {
    text = ''
      [colors]
      [colors.bright]
      black = "#5e5c64"
      blue = "#2a7bde"
      cyan = "#33c7de"
      green = "#33d17a"
      magenta = "#c061cb"
      red = "#f66151"
      white = "#ffffff"
      yellow = "#e9ad0c"

      [colors.normal]
      black = "#171421"
      blue = "#12488b"
      cyan = "#2aa1b3"
      green = "#26a269"
      magenta = "#a347ba"
      red = "#c01c28"
      white = "#d0cfcc"
      yellow = "#a2734c"

      [colors.primary]
      background = "#ffffff"
      foreground = "#171421"
    '';
  };
}
