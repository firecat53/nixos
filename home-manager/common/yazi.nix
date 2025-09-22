{
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    enableBashIntegration = true;
    plugins = {
      inherit (pkgs.yaziPlugins) git smart-enter toggle-pane;
    };
    settings = {
      mgr = {
        ratio = [
          1
          3
          4
        ];
      };
      opener = {
        extract = [
          {
            run = "ya pub extract --list \"$@\"";
            desc = "Extract here";
            for = "unix";
          }
        ];
      };
      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          run = "close";
          on = "q";
          desc = "Close tab or quit on last tab";
        }
        {
          run = "shell 'ripdrag -bx \"$@\" 2>/dev/null &' --confirm";
          on = "<C-d>";
          desc = "Activate ripdrag for current selection";
        }
        {
          run = "plugin smart-enter";
          on = "l";
          desc = "Enter child directory or open file";
        }
        {
          run = "plugin smart-enter";
          on = "<Enter>";
          desc = "Enter child directory or open file";
        }
        {
          run = "shell $SHELL --block";
          on = "!";
          desc = "Open shell here";
        }
        {
          run = "plugin toggle-pane max-preview";
          on = "i";
          desc = "Maximize or restore the preview pane";
        }
        {
          run = "shell 'wl-copy < \"$@\"'";
          on = "C";
          desc = "Copy file contents to clipboard";
        }
      ];
    };
    initLua = ''
      require("git"):setup()
      Status:children_add(function()
        local h = cx.active.current.hovered
        if not h or ya.target_family() ~= "unix" then
          return ""
        end

        return ui.Line {
          ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
          ":",
          ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
          " ",
        }
      end, 500, Status.RIGHT)
      Header:children_add(function()
        if ya.target_family() ~= "unix" then
          return ""
        end
        return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
      end, 500, Header.LEFT)
    '';
  };
}
