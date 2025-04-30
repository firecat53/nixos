# Note: remember to run smbpasswd -a jamia to add allowed user
{
  lib,
  pkgs,
  ...
}:
{
  users.users.jamia = {
    isNormalUser = true;
    # password: jamia
    initialHashedPassword = "$6$k8coMrkwglvFvVkR$JT7GBZ7v/iEtvVAuv9GKlE57ZqP9ztDbPoHfx6v.yYXDYo7YwXpslRqoFzKfzXpTiG6RRwztSRYmCjaiSCR.L1";
  };

  # Install kopia for looking at backups
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # Ensure /home/jamia/backups is mounted at boot.
  # Ensure ZFS properties set `canmount=true` and `mountpoint=/home/jamia/backups`
  systemd.services.zfs-mount.enable = lib.mkForce true;
}
