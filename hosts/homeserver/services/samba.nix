# Note: remember to run smbpasswd -a <user> to add allowed users
{
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
      server string = homeserver
      netbios name = homeserver
      security = user 
      hosts allow = 192.168.200. 10.200.200. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      homes = {
        comment = "Home directories";
        "valid users" = "%S";
        browseable = "no";
        writeable = "yes";
        "read only" = "no";
      };
      media = {
        comment = "Family Media";
        path = "/mnt/media";
        browseable = "yes";
        public = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "force user" = "firecat53";
        "force group" = "users";
        printable = "no";
        writable = "no";
        "write list" = "firecat53";
      };
      downloads = {
        comment = "Downloaded Media";
        path = "/mnt/downloads";
        "valid users" = "firecat53, chryspie";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
        public = "no";
      };
    };
  };
}
