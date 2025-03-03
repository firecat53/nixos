{
  config,
  lib,
  ...
}:
{
  # Systemd-boot Configuration with plymouth
  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
    initrd = {
      systemd = {
        enable = true;
      };
      verbose = false;
    };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
    };
    plymouth = lib.mkIf (config.networking.hostName == "laptop") {
      enable = true;
    };
  };
}
