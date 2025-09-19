{
  pkgs,
  ...
}:
let
  initLuaFile = pkgs.writeText "init.lua" ''
    require("git"):setup()
  '';
in
{
  programs.yazi = {
    enable = true;
    initLua = initLuaFile;
    package = pkgs.unstable.yazi;
    plugins = {
      inherit (pkgs.yaziPlugins) git smart-enter toggle-pane;
    };
    settings = {
      yazi = {
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
        ];
      };
    };
  };
}
