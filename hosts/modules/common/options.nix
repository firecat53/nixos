{
  lib,
  ...
}:
{
  options = {
    isVirtual = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system is running in a virtual environment";
    };
    latestZFSKernel = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use latest available ZFS compatible kernel";
    };
    tmuxStatusColor = lib.mkOption {
      type = lib.types.str;
      default = "#cba6f7"; # catppuccin mocha mauve
      description = "Tmux status bar background color";
    };
  };
}
