{
  ...
}:
{
  # Systemd-boot Configuration.
  boot = {
    initrd.systemd.enable = true;
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
