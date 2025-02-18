# ZFS configs/backups
{
  pkgs,
  ...
}:{
  boot = {
    supportedFilesystems = ["zfs"];
    zfs = {
      requestEncryptionCredentials = true;
      forceImportRoot = false;
      devNodes = "/dev";
    };
  };

  environment.systemPackages = with pkgs; [
    lzop
    mbuffer
    pv
  ];

  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
}
