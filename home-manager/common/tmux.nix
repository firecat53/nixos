{
  pkgs,
  ...
}:{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 10;
    historyLimit = 5000;
    keyMode = "vi";
    newSession = true;
    shortcut = "a";
    terminal = "tmux-256color";
    extraConfig = ''
      set-option -ga terminal-overrides ",alacritty:Tc"
      set -s copy-command 'wl-copy'

      # Capture URL's from tmux and pass to urlscan
      bind-key u capture-pane \; save-buffer /tmp/tmux-buffer \; new-window -n urlscan "urlscan -cd /tmp/tmux-buffer"

      # Last active window
      unbind l
      bind C-a last-window
      bind C-d detach-client
      unbind " "
      bind " " next-window
      bind C-" " next-window
      bind C-c new-window
      bind C-n next-window
      bind C-p previous-window
      bind v run "tmux show-buffer | wl-paste > /dev/null"

      # Define sessions
      new -s term -n term -d -A
      new -s comms -n comms -d -A mutt
      new -s music -n music -d -A
    '';
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha' # latte,frappe, macchiato or mocha

          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator " "
          set -g @catppuccin_window_middle_separator " █"
          set -g @catppuccin_window_number_position "right"

          set -g @catppuccin_window_default_fill "number"

          set -g @catppuccin_window_current_fill "number"

          set -g @catppuccin_status_modules_right "host uptime date_time"
          set -g @catppuccin_status_left_separator  ""
          set -g @catppuccin_status_right_separator " "
          set -g @catppuccin_status_fill "all"
          set -g @catppuccin_status_connect_separator "yes"
        '';
      }
    ];
  };
}
