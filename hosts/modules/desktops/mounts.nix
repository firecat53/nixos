{
  config,
  pkgs,
  ...
}:{
  environment.systemPackages = with pkgs; [
    cifs-utils
    davfs2
  ];

  sops.secrets = {
    smbcreds = {
      mode = "0600";
    };
    davfs = {
      mode = "0600";
      path = "/etc/davfs2/secrets";
    };
  };

  services.davfs2.enable = true;

  systemd.mounts = [
    {
      description = "Samba mount for downloads";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      what = "//192.168.200.101/downloads";
      where = "/mnt/homeserver-downloads";
      options = "credentials=${config.sops.secrets.smbcreds.path},iocharset=utf8,rw,x-systemd.automount,uid=1000,gid=100,vers=3";
      type = "cifs";
    }
    {
      description = "Samba mount for homeserver media";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      what = "//192.168.200.101/media";
      where = "/mnt/homeserver-media";
      options = "credentials=${config.sops.secrets.smbcreds.path},iocharset=utf8,rw,x-systemd.automount,uid=1000,gid=100,vers=3";
      type = "cifs";
    }
    {
      description = "Nextcloud webdav mount";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      what = "https://nc.firecat53.net/remote.php/webdav";
      where = "/mnt/nextcloud";
      options = "x-systemd.automount,uid=1000,gid=100";
      type = "davfs";
    }
  ];
  systemd.automounts = [
    {
      description = "Samba automount for downloads";
      where = "/mnt/homeserver-downloads";
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "2m";
      };
    }
    {
      description = "Samba automount for homeserver media";
      where = "/mnt/homeserver-media";
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "2m";
      };
    }
    {
      description = "Nextcloud webdav automount";
      where = "/mnt/nextcloud";
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "2m";
      };
    }
  ];
}
