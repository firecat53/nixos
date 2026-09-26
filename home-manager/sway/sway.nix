{
  config,
  inputs,
  lib,
  mailFolders,
  pkgs,
  ...
}:
let
  mod = "Mod4";
  mod1 = "Mod1";
  ## Ensure correct path to my flake-installed projects
  bwm = inputs.bwm.packages.${pkgs.stdenv.hostPlatform.system}.default;
  km = inputs.keepmenu.packages.${pkgs.stdenv.hostPlatform.system}.default;
  tdcm = inputs.todocalmenu.packages.${pkgs.stdenv.hostPlatform.system}.default;
  wdm = inputs.watson-dmenu.packages.${pkgs.stdenv.hostPlatform.system}.default;
  inbox = "${config.accounts.email.accounts."firecat53.net".maildir.absPath}/${mailFolders.inbox}";
  # Mail is unread when its maildir filename carries no S flag. Counting new/
  # instead (what the maildir block does) misses nearly all of it: mbsync,
  # notmuch and neomutt each relocate mail to cur/ while it's still unread
  mailUnread = pkgs.writeShellScript "mail-unread" ''
    count=$(${pkgs.fd}/bin/fd --type f . ${inbox}/new ${inbox}/cur \
      | ${pkgs.ripgrep}/bin/rg --count --invert-match ':2,[A-Z]*S[A-Z]*$' || true)
    count=''${count:-0}
    if [ "$count" -ge 10 ]; then
      state=critical
    elif [ "$count" -ge 1 ]; then
      state=warning
    else
      state=idle
    fi
    printf '{"icon":"mail","state":"%s","text":"%s"}\n' "$state" "$count"
  '';
  jq = "${pkgs.jq}/bin/jq";
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  term = "${config.programs.kitty.package}/bin/kitty";
  neomutt = "${config.programs.neomutt.package}/bin/neomutt";
  yazi = "${config.programs.yazi.package}/bin/yazi";
  # Size the terminal itself at 80% of the output: a for_window `resize set`
  # never reaches the hidden window, which reverts to its default size on show
  scratchTerm = pkgs.writeShellScript "scratch-term" ''
    read -r width height < <(${swaymsg} -t get_outputs | ${jq} -r '.[] | select(.focused)
      | "\(.rect.width * 0.8 | floor) \(.rect.height * 0.8 | floor)"')
    exec ${term} --app-id scratchterm -o remember_window_size=no \
      -o initial_window_width="$width" -o initial_window_height="$height"
  '';
  # Cycle through every window on the workspace, wrapping at the ends.
  # `focus next` jumps to the adjacent output instead of wrapping
  cycleFocus = pkgs.writeShellScript "cycle-focus" ''
    id=$(${swaymsg} -t get_tree | ${jq} --argjson step "$1" '
      [.. | objects | select(.type == "workspace" and any(.. | objects; .focused))]
      | first // empty
      | [.. | objects | select(.pid)]
      | (map(.focused) | index(true)) as $i
      | if $i == null then empty else .[($i + $step) % length].id end')
    [ -n "$id" ] && ${swaymsg} "[con_id=$id] focus"
  '';
  scratchpadCount = pkgs.writeShellScript "scratchpad-count" ''
    count() {
      ${swaymsg} -t get_tree | ${jq} -c '
        [.. | objects | select(.name == "__i3_scratch") | .floating_nodes[]] | length
        | {text: (if . > 0 then " \(.)" else "" end), state: "info"}'
    }
    count
    ${swaymsg} -r -m -t subscribe '["window", "workspace"]' | while read -r _; do count; done
  '';
  # Enter cancels; Tab then Enter exits
  exitSway = pkgs.writeShellScript "exit-sway" ''
    choice=$(printf 'Cancel\nExit sway\n' \
      | ${config.programs.bemenu.package}/bin/bemenu --prompt 'Exit sway?')
    [ "$choice" = "Exit sway" ] && ${swaymsg} exit
  '';
in
{
  sops.secrets.openweathermap_api = { };

  wayland.windowManager.sway = {
    enable = true;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    config = {

      assigns = {
        "1" = [
          { app_id = "Terminal"; }
        ];
        "2" = [
          { app_id = "firefox"; }
        ];
        "3" = [
          { app_id = "comms"; }
        ];
        "4" = [
          { app_id = "music"; }
          { class = "Spotify"; }
        ];
        "5" = [
          { app_id = "libreoffice.*"; }
          { app_id = "virt-manager"; }
          { app_id = "virt-viewer"; }
        ];
      };

      bars = [
        {
          position = "top";
          fonts = {
            names = [ "pango:Maple Mono NF" ];
            size = 15.0;
          };
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-top.toml";
          workspaceButtons = true;
          workspaceNumbers = true;
          colors = {
            background = "$base";
            statusline = "$text";
            focusedStatusline = "$text";
            focusedSeparator = "$base";

            focusedWorkspace = {
              background = "$sapphire";
              border = "$base";
              text = "$crust";
            };
            activeWorkspace = {
              background = "$surface2";
              border = "$base";
              text = "$text";
            };
            inactiveWorkspace = {
              background = "$base";
              border = "$base";
              text = "$text";
            };
            urgentWorkspace = {
              background = "$red";
              border = "$base";
              text = "$crust";
            };
          };
        }
      ];

      colors = {
        background = "$base";
        focused = {
          childBorder = "$lavender";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$lavender";
        };
        focusedInactive = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$overlay0";
        };
        unfocused = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$overlay0";
        };
        urgent = {
          childBorder = "$peach";
          background = "$base";
          text = "$peach";
          indicator = "$overlay0";
          border = "$peach";
        };
        placeholder = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$overlay0";
          border = "$overlay0";
        };
      };
      floating.modifier = "${mod}";

      fonts = {
        names = [ "pango:Hack" ];
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

      keybindings =
        let
          andcli = "${pkgs.andcli}/bin/andcli";
          brightness = "${pkgs.brightnessctl}/bin/brightnessctl";
          browser = "${pkgs.firefox}/bin/firefox";
          bottom = "${pkgs.bottom}/bin/btm";
          chroncal = "${config.programs.chroncal.package}/bin/chroncal";
          gh-dash = "${pkgs.gh-dash}/bin/gh-dash";
          keepmenu = "${km}/bin/keepmenu";
          nmdm = "${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu";
          notify = "${pkgs.mako}/bin/makoctl";
          pass = "${bwm}/bin/bwm";
          pass_gui = "${pkgs.keepassxc}/bin/keepassxc";
          rofimoji = "${pkgs.rofimoji}/bin/rofimoji --selector fuzzel --skin-tone light";
          swaylock = "${pkgs.swaylock}/bin/swaylock";
          todocalmenu = "${tdcm}/bin/todocalmenu -cmd bemenu -todo ${config.home.homeDirectory}/.local/share/nextcloud/calendars/";
          vim = "${pkgs.nvim-pkg}/bin/nvim";
          vol = "${pkgs.wireplumber}/bin/wpctl";
          vol_gui = "${pkgs.pwvucontrol}/bin/pwvucontrol";
          watson = "${wdm}/bin/watson_dmenu";
        in
        lib.mkOptionDefault {
          ## General keybindings/apps
          "${mod}+i" = "exec ${nmdm}";
          "${mod}+m" = "exec ${term} --app-id comms --title comms ${neomutt}";
          "${mod}+n" =
            "exec ${term} --title Notes -e ${vim} '${config.home.homeDirectory}/docs/family/scott/wiki/quicknote.md'";
          "${mod}+p" = "exec ${term} --title bottom ${bottom}";

          "${mod}+${mod1}+c" = "exec ${term} --title calendar -e ${chroncal}";
          "${mod}+${mod1}+g" = "exec ${term} --title gh-dash ${gh-dash}";
          "${mod}+${mod1}+j" = "exec ${rofimoji}";
          "${mod}+${mod1}+k" = "exec ${keepmenu}";
          "${mod}+${mod1}+l" = "exec ${swaylock}";
          "${mod}+${mod1}+m" =
            "exec ${term} ${andcli} -t aegis ${config.home.homeDirectory}/shared/passwords/aegis-latest.json";
          "${mod}+${mod1}+s" = "exec ${watson}";
          "${mod}+${mod1}+t" = "exec ${todocalmenu}";
          "${mod}+${mod1}+w" =
            ''exec ${term} --app-id Wiki --title Wiki -e ${vim} "${config.home.homeDirectory}/docs/family/scott/wiki/Home.md"'';
          "${mod}+${mod1}+space" = "exec ${pass}";

          "${mod}+${mod1}+Shift+l" = "exec systemctl suspend";

          "${mod}+Shift+m" = "exec ${term} --app-id music --title music";
          "${mod}+Shift+p" = "exec ${pass_gui}";
          "${mod}+Shift+w" = "exec ${browser}";

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
          "${mod}+Shift+e" = "exec ${exitSway}";
          "${mod}+d" = ''exec j4-dmenu-desktop --dmenu="bemenu" --term="${term}"'';

          ## Shotman screenshots
          "${mod}+y" = "exec shotman --capture region";
          "${mod}+Shift+y" = "exec shotman --capture window";
          "${mod}+${mod1}+y" = "exec shotman --capture output";

          ## Motion bindings
          "${mod}+Tab" = "workspace back_and_forth";
          # Moved to extraConfig
          "${mod}+0" = null;
          "${mod1}+Tab" = "exec ${cycleFocus} 1";
          "${mod1}+Shift+Tab" = "exec ${cycleFocus} -1";
        };

      modifier = "${mod}";

      output = {
        eDP-1 = {
          scale = "1";
        };
        HDMI-A-1 = {
          scale = "1.5";
        };
      };

      startup = [
        # Scratchpad shell, yazi and a nixos shell on 1, mail on 3
        { command = "${scratchTerm}"; }
        { command = "${term} --app-id Terminal ${yazi}"; }
        {
          command = "${term} --app-id Terminal --working-directory ${config.home.homeDirectory}/nixos/nixos";
        }
        { command = "${term} --app-id comms --title comms ${neomutt}"; }
        # Unlock the device key into ssh-agent. A normal window, not an
        # overlay prompt, so bwm can type the passphrase into it
        { command = "${term} --app-id ssh-add ${pkgs.openssh}/bin/ssh-add"; }
      ];

      terminal = term;

      window.commands = [
        {
          command = "floating enable";
          criteria = {
            app_id = "pinentry-qt";
          };
        }
        {
          command = "floating enable, resize set 600 150, move position center";
          criteria = {
            app_id = "ssh-add";
          };
        }
        {
          command = "floating enable";
          criteria = {
            title = "shotman";
          };
        }
        {
          command = "floating enable, move position center, move scratchpad";
          criteria = {
            app_id = "scratchterm";
          };
        }
        {
          command = "move to workspace 4; workspace 4";
          criteria = {
            class = "Spotify";
          };
        }
      ];

      workspaceLayout = "tabbed";
    };
    # Sway names its first workspace after the earliest `workspace` binding,
    # and the generated bindings sort Mod4+0 (10) ahead of Mod4+1
    extraConfig = ''
      bindsym ${mod}+0 workspace number 10
    '';
    extraSessionCommands = ''
      export AWT_TOOLKIT="MToolkit"
      export BEMENU_BACKEND="$XDG_SESSION_TYPE"
      export EDITOR="nvim"
      export GDK_DPI_SCALE="1.25"
      export _JAVA_AWT_WM_NONREPARENTING="1"
      # --no-vbell: -Q otherwise swaps in the terminfo flash, which kitty has
      export LESS="-QiR --no-vbell"
      export LIBVIRT_DEFAULT_URI="qemu:///system"
      export NIXOS_OZONE_WL="1"
      export OPENWEATHERMAP_API_KEY=$(cat "${config.xdg.configHome}/sops-nix/secrets/openweathermap_api")
      export QT_AUTO_SCREEN_SCALE_FACTOR="1"
      export QT_QPA_PLATFORM=wayland
      export QT_SCALE_FACTOR="1.5"
      export XDG_SCREENSHOTS_DIR="${config.home.homeDirectory}/.local/tmp"
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
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock";
      "lock" = "${pkgs.swaylock}/bin/swaylock";
    };
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
      {
        timeout = 7200;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };

  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        icons = "awesome4";
        theme = "ctp-mocha";
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
            block = "custom";
            command = "${scratchpadCount}";
            persistent = true;
            json = true;
            hide_when_empty = true;
          }
          {
            block = "watson";
            show_time = false;
            state_path = "${config.home.homeDirectory}/docs/family/scott/src/state/watson/state";
          }
          {
            block = "custom";
            command = "pgrep -x pianobar >/dev/null && awk -F '=' '/^artist=/ ||
            /^title=/ {printf \"%s - \",$2}' ${config.xdg.configHome}/pianobar/nowplaying | sed 's/ - $//'";
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
            device = "BAT*";
            format = " $icon  $percentage | ";
            full_format = "";
            missing_format = "";
          }
          {
            block = "custom";
            command = "${mailUnread}";
            json = true;
            watch_files = [
              "${inbox}/new"
              "${inbox}/cur"
            ];
            interval = 20;
          }
          {
            block = "weather";
            format = " $icon {$temp}C ";
            service = {
              name = "openweathermap";
              units = "metric";
              coordinates = [
                "48.0171"
                "-122.0672"
              ];
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
    size = 32;
    gtk.enable = true;
    x11 = {
      enable = true;
    };
  };
  gtk = {
    enable = true;
  };
}
