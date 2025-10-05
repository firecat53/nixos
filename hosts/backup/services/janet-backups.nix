{
  lib,
  pkgs,
  ...
}:
{
  users.users.janet = {
    isNormalUser = true;
    # password: janet
    initialHashedPassword = "$y$j9T$PpUuFhfd7P/WPJcUloiXt.$8MeNlKhF1TRZJEjKfpoYPsAvZSnKBnr1o6hhPsSwN0D";
  };

  # Install kopia for looking at backups
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # Ensure /home/janet/backups is mounted at boot.
  # Ensure ZFS properties set `canmount=true` and `mountpoint=/home/janet/backups`
  systemd.services.zfs-mount.enable = lib.mkForce true;
}
