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
  };
  catppuccin.tmux = {
    enable = true;
    extraConfig = ''
      set -g status-left ""
      set -g status-right-length 50
      set -g status-right "#{E:@catppuccin_status_host}"
      set -ga status-right "#{E:@catppuccin_status_uptime}"
      set -ga status-right "#{E:@catppuccin_status_date_time}"

      set -g @catppuccin_window_status_style "rounded"
      set -g @catppuccin_window_number_position "right"
      set -g @catppuccin_window_text " #{window_name}"

      set -g @catppuccin_window_current_text " #{window_name}"
      set -g @catppuccin_window_current_text_color "#{@thm_mauve}"

      set -g @catppuccin_status_connect_separator "yes"
    '';
  };
}
