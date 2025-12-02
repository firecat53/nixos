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
  };
}
