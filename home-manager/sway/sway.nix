{
  config,
  lib,
  pkgs,
  ...
}: let
  mod = "Mod4";
  mod1 = "Mod1";
in {
  sops.secrets.openweathermap_api = {};
  sops.secrets.openweathermap_zip = {};

  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    config = {

      assigns = {
        "1" = [
          { app_id = "Terminal"; }
          { class = "VSCodium"; }
        ];
        "2" = [
          { app_id = "firefox"; }
        ];
        "3" = [
          { app_id = "comms"; }
        ];
        "4" = [
          { app_id = "music"; }
          { app_id = "ncspot"; }
          { class = "Spotify"; }
        ];
        "5" = [
          { app_id = "libreoffice.*"; }
          { app_id = "pdfarranger"; }
          { app_id = "virt-manager"; }
          { app_id = "virt-viewer"; }
        ];
      };

      bars = [
        {
          position = "top";
          fonts = {
            names = ["pango:SauceCodePro Nerd Font"];
            size = 15.0;
          };
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs /home/firecat53/.config/i3status-rust/config-top.toml";
          colors = {
              separator = "#666666";
              background = "#222222";
              statusline = "#dddddd";
              focusedWorkspace = {
                background = "#0088CC";
                border = "#0088CC";
                text = "#ffffff";
              };
              activeWorkspace = {
                background = "#333333";
                border = "#333333";
                text = "#ffffff";
              };
              inactiveWorkspace = {
                background = "#333333";
                border = "#333333";
                text = "#888888";
              };
              urgentWorkspace = {
                background = "#ff0000";
                border = "#900000";
                text = "#ffffff";
              };
            };
          workspaceButtons = true;
          workspaceNumbers = true;
        }
      ];
      floating.modifier = "${mod}";

      fonts = {
        names = ["pango:Hack"];
        size = 9.0;
      };

      input = {
        "1739:52619:SYNA8006:00_06CB:CD8B_Touchpad" = {
          tap = "enabled";
        };
        "type:keyboard" = {
          xkb_options = "caps:escape";
        };
      };

      keybindings = let
          brightness = "${pkgs.brightnessctl}/bin/brightnessctl";
          browser = "${pkgs.firefox}/bin/firefox";
          bottom = "${pkgs.bottom}/bin/btm";
          gh-dash = "${pkgs.gh-dash}/bin/gh-dash";
          ikhal = "${pkgs.kahl}/bin/ikhal";
          keepmenu = "keepmenu";
          nmdm = "${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu";
          notify = "${pkgs.mako}/bin/makoctl";
          pass = "bwm";
          pass_gui = "${pkgs.keepassxc}/bin/keepassxc";
          rofimoji = "${pkgs.rofimoji}/bin/rofimoji --selector fuzzel --skin-tone light";
          swaylock = "${pkgs.swaylock}/bin/swaylock";
          term = "${pkgs.alacritty}/bin/alacritty";
          tmux = "${pkgs.tmux}/bin/tmux";
          vim = "${pkgs.vim}/bin/vim";
          vol = "${pkgs.wireplumber}/bin/wpctl";
          vol_gui = "${pkgs.pwvucontrol}/bin/pwvucontrol";
        in lib.mkOptionDefault {
          ## General keybindings/apps
          "${mod}+i" = "exec ${nmdm}";
          "${mod}+m" = "exec ${term} --class comms --title comms -e ${tmux} new -d -A -s comms";
          "${mod}+n" = "exec ${term} --title Notes -e ${vim} '/home/firecat53/docs/family/scott/wiki/QuickNote.md'";
          "${mod}+p" = "exec ${term} --title ${bottom} -e btm";
          "${mod}+z" = "exec ${term} --class Terminal --title Terminal -e ${tmux} new -d -A -s term";

          "${mod}+${mod1}+c" = "exec ${term} --title calendar -e ikhal";
          "${mod}+${mod1}+g" = "exec ${term} --title ${bottom} -e ${gh-dash}";
          "${mod}+${mod1}+j" = "exec ${rofimoji}";
          "${mod}+${mod1}+k" = "exec ${keepmenu}";
          "${mod}+${mod1}+l" = "exec ${swaylock} -i /tmp/wall.png";
          "${mod}+${mod1}+s" = "exec watson_dmenu";
          "${mod}+${mod1}+w" = ''exec ${term} --class Wiki --title Wiki -e ${vim} "/home/firecat53/docs/family/scott/wiki/Home.md"'';
          "${mod}+${mod1}+space" = "exec ${pass}";

          "${mod}+${mod1}+Shift+l" = "exec systemctl suspend";

          "${mod}+Shift+m" = "exec ${term} --class music --title music -e ${tmux} new -d -A -s music";
          "${mod}+Shift+p" = "exec ${pass_gui}";
          "${mod}+Shift+w" = "exec ${browser}";
          "${mod}+Shift+z" = "exec ${term} --class Term --title Term";

          ## Notifications
          "Control+grave" = "exec ${notify} dismiss";
          "Control+shift+grave" = "exec ${notify} restore";

          ## Media/brightness controls
          "XF86MonBrightnessDown" = "exec ${brightness} -q set 5%-";
          "XF86MonBrightnessUp" = "exec ${brightness} -q set +5%";
          "${mod}+${mod1}+comma" = "exec playerctl previous";
          "${mod}+${mod1}+period" = "exec playerctl next";
          "${mod}+${mod1}+p" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioPrev" = "exec playerctl previous";
          "XF86AudioStop" = "exec playerctl stop";
          "XF86AudioMute" = "exec ${vol} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioLowerVolume" = "exec ${vol} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioRaiseVolume" = "exec ${vol} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
          "${mod}+${mod1}+v" = "exec ${vol_gui}";

          ## Modify default bindings
          "${mod}+Control+space" = "focus mode_toggle";
          "${mod}+d" = ''exec j4-dmenu-desktop --dmenu="bemenu" --term="${term}"'';

          ## Shotman screenshots
          "${mod}+y" = "exec shotman --capture region";
          "${mod}+Shift+y" = "exec shotman --capture window";
          "${mod}+${mod1}+y" = "exec shotman --capture output";

          ## Motion bindings
          "${mod}+Tab" =  "workspace back_and_forth";
        };

      modifier = "${mod}";

      output = {
        eDP-1 = {
          scale = "1";
        };
      };

      startup = [
        { command = "dbus-update-activation-environment --systemd --all"; }
        { command = "systemctl --user restart sway-session.target"; }
        { command = "systemctl --user restart wallpaper.service"; }
      ];

      terminal = "${pkgs.alacritty}/bin/alacritty";

      window.commands = [
        {
          command = "floating enable";
          criteria = {
            app_id = "pinentry-qt";
            title = "shotman";
          };
        }
        {
          command = "move to workspace 1; workspace 1";
          criteria = {
            class = "VSCod.*";
          };
        }
        {
          command = "move to workspace 4; workspace 4";
          criteria = {
            class = "Spotify";
            app_id = "ncspot";
          };
        }
      ];
        
      workspaceLayout = "tabbed";
    };
    extraSessionCommands = ''
      export AWT_TOOLKIT="MToolkit"
      export BEMENU_BACKEND="$XDG_SESSION_TYPE"
      export EDITOR="vim"
      export GDK_DPI_SCALE="1.25"
      export _JAVA_AWT_WM_NONREPARENTING="1"
      export LESS="QiR"
      export LIBVIRT_DEFAULT_URI="qemu:///system"
      export NIXOS_OZONE_WL="1"
      export OPENWEATHERMAP_API_KEY=$(cat "$HOME/.config/sops-nix/secrets/openweathermap_api")
      export OPENWEATHERMAP_ZIP=$(cat "$HOME/.config/sops-nix/secrets/openweathermap_zip")
      export QT_AUTO_SCREEN_SCALE_FACTOR="1"
      export QT_QPA_PLATFORM=wayland
      export QT_SCALE_FACTOR="1.5"
    '';
  };
  programs.swaylock = {
    enable = true;
    settings = {
      daemonize = true;
      image = "/tmp/wall.png";
    };
  };
  services.swayidle = {
    enable = true;
    events = [
      { 
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock}/bin/swaylock";
      }
    ];
    timeouts = [
      {
        timeout = 600;
        command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
      }
      {
        timeout = 610;
        command = "${pkgs.swaylock}/bin/swaylock";
      }
    ];
  };

  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        icons = "awesome4";
        theme = "slick";
        blocks = [
          {
            block = "custom";
            command = "awk '{printf(\" %s\",$1)}' <(systemctl --user --state failed --plain -q) <(systemctl --state failed --plain -q)";
            hide_when_empty = true;
            interval = 5;
            theme_overrides = {
              idle_bg = "#f44336";
            };
          }
          {
            block = "watson";
            show_time = false;
            state_path = "/home/firecat53/.config/watson/state";
          }
          {
            block = "custom";
            command = "[ $(pgrep pianobar) ] && awk -F '=' '/^artist=/ || /^title=/ {printf \"%s - \",$2}' /home/firecat53/.config/pianobar/nowplaying | sed 's/ - $//'";
            interval = 5;
          }
          {
            block = "music";
            format = " {$combo.str(max_w:25,rot_interval:0.5) $play |}";
          }
          {
            block = "sound";
          }
          {
            block = "net";
            format = " ↓{$speed_down.eng(w:3,u:b,p:M) ↑$speed_up.eng(w:3,u:b,p:M)} ";
            format_alt = " $ip ";
            interval = 3;
            missing_format = " X ";
          }
          {
            block = "net";
            device = "^wg.*|^AirVPN.*";
            format = "$device";
            missing_format = "";
            interval = 3;
            theme_overrides = {
              idle_bg = "#8bc34a";
              idle_fg = "#000000";
            };
          }
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            format = " $available ";
            interval = 20;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "load";
            interval = 3;
            format = " $1m.eng(w:3) $5m.eng(w:3) ";
          }
          {
            block = "battery";
            format = " $icon  $percentage | ";
            full_format = "";
          }
          {
            block = "maildir";
            interval = 20;
            inboxes = ["~/mail/scottandchrystie/INBOX" "~/mail/firecat4153/INBOX" "~/mail/firecat53.net/Inbox"];
            threshold_warning = 1;
            threshold_critical = 10;
            display_type = "new";
          }
          {
            block = "weather";
            format = " $icon {$temp}C ";
            service = {
              name = "openweathermap";
              units = "metric";
            };
          }
          {
            icons_format = " ";
            block = "time";
            interval = 60;
            format = {
              full = " $timestamp.datetime(f:'%a %m/%d %R') ";
              short = " $timestamp.datetime(f:%R) ";
            };
          }
        ];
      };
    };
  };
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.gnome.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };
  gtk = {
    enable = true;
    theme = {
      package = pkgs.gnome.gnome-themes-extra;
      name = "Adwaita";
    };
  };
}
