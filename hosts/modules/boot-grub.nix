{
  # Grub Configuration with plymouth
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
      grub = {
        enable = true;
        configurationLimit = 10;
      };
    };
  };
}
