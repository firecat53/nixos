# Note: remember to run smbpasswd -a jamia to add allowed user
{
  config,
  pkgs,
  ...
}:{
  users.users.jamia = {
    isNormalUser = true;
    # password: jamia
    initialHashedPassword = "$6$k8coMrkwglvFvVkR$JT7GBZ7v/iEtvVAuv9GKlE57ZqP9ztDbPoHfx6v.yYXDYo7YwXpslRqoFzKfzXpTiG6RRwztSRYmCjaiSCR.L1";
  };

  # Install kopia for looking at backups
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # For Samba mount
  fileSystems = {
    "/home/jamia/backups" = {
      device = "backuppool/jamia";
      fsType = "zfs";
      options = ["X-mount.mkdir"];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/samba/private 0755 root root - "
    "d /var/log/samba/ 0755 root root - "
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = HOME
      server string = backup
      netbios name = backup
      security = user 
      hosts allow = 192.168.200. 10.200.200. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      backups = {
        comment = "Backup directory";
        path = "/home/jamia/backups";
        "valid users" = "jamia";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
      };
    };
  };
}
