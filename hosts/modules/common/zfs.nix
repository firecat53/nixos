# ZFS configs/backups
{
  pkgs,
  ...
}:{
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
