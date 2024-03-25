{
  config,
  lib,
  ...
}:{
  # Grub Configuration with plymouth and ZFS
  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet" "udev.log_level=3"];
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
    plymouth = lib.mkIf (config.networking.hostName == "office") {
      enable = true;
    };
    supportedFilesystems = ["zfs"];
    zfs = {
      requestEncryptionCredentials = true;
      forceImportRoot = false;
      devNodes = "/dev/disk/by-id";
    };
  };
}
