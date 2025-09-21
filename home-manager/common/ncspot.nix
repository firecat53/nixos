{
  pkgs,
  ...
}:
{
  programs.ncspot = {
    enable = true;
    package = pkgs.unstable.ncspot;  # TODO: change to stable when 1.3.1 lands there
    settings = {
      theme = {
        background = "#181825";
        primary = "#CDD6F4";
        secondary = "#313244";
        title = "#CBA6F7";
        playing = "#FAB387";
        playing_selected = "#A6E3A1";
        playing_bg = "#11111B";
        highlight = "#A6E3A1";
        highlight_bg = "#11111B";
        error = "#F5E0DC";
        error_bg = "#F38BA8";
        statusbar = "#FAB387";
        statusbar_progress = "#313244";
        statusbar_bg = "#181825";
        cmdline = "#74C7EC";
        cmdline_bg = "#181825";
      };
    };
  };
}
