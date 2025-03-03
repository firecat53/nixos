{
  pkgs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    package = pkgs.unstable.yazi;
    enableBashIntegration = true;
    keymap = {
      manager.prepend_keymap = [
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
      ];
    };
  };
}
