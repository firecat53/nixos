{
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    package = pkgs.unstable.yazi;
    enableBashIntegration = true;
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
    '';
  };
}
