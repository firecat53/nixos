{
  ...
}:
{
  # Systemd-boot Configuration. Plymouth is enabled in modules/desktops.
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
  };
}
