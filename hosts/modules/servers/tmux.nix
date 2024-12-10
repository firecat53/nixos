# TODO - host variable for status-bg color
{
  ### Tmux
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

      # Highlighting the active window in status bar
      setw -g window-status-current-style bg=red
      set -g status-bg magenta
      set -g status-fg black

      # Add uptime to status bar
      set -g status-interval 5
      set -g status-right-length 100
      set -g status-right "#(uptime | awk -F 'up |,' '{print \"up\",$2}' | sed 's/  / /g') #(awk -F ' ' '{print $1,$2,$3}' /proc/loadavg) \"#H\" #(date '+%H:%M %a %m-%d')"
    '';
  };
}
