{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Scrollback as plain text in a read-only nvim overlay: vim search, visual
  # select and yank straight to the clipboard. q quits
  nvimPager =
    source:
    lib.concatStringsSep " " [
      "launch --type=overlay --stdin-source=${source}"
      "${pkgs.nvim-pkg}/bin/nvim -R -"
      ''-c "set clipboard=unnamedplus nonumber norelativenumber"''
      ''-c "nnoremap q <cmd>qa!<cr>"''
      ''-c "normal G"''
    ];
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF";
      size = 16;
    };
    settings = {
      scrollback_lines = 100000;
      # Negative: hide as soon as typing starts
      mouse_hide_wait = -1;
      # Sway's kill closes the window, as with foot
      confirm_os_window_close = 0;
      # The bell's urgency hint flashes sway's urgent border on the tab
      window_alert_on_bell = false;
      enable_audio_bell = false;
    };
    keybindings = {
      "ctrl+shift+h" = nvimPager "@screen_scrollback";
      "ctrl+shift+g" = nvimPager "@last_cmd_output";
      "ctrl+shift+n" = "new_os_window_with_cwd";
      "super+z" = "launch --type=os-window --cwd=current ${config.programs.yazi.package}/bin/yazi";
    };
  };
}
