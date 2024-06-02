# Nextcloud
{
  config,
  pkgs,
  sops,
  ...
}:{
  sops.secrets.nextcloud-admin-password = {
    # This has to be world readable because I can't set ACLs with sops-nix for the 
    #   alertmanager systemd dynamic user. TODO
    mode = "0444";
    owner = config.users.users.nextcloud.name;
    group = config.users.users.nextcloud.group;
  };
  users.users.nextcloud.extraGroups = ["users"];
  services.nginx.virtualHosts."nc.firecat53.com".listen = [ { addr = "127.0.0.1"; port = 8082; } ];
 
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nc.firecat53.com";
    database.createLocally = true;
    configureRedis = true;
    config = {
      adminuser = "firecat53";
      adminpassFile = "${config.sops.secrets.nextcloud-admin-password.path}";
      dbtype = "mysql";
    };
    settings = {
      default_phone_region = "US";
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
      mysql.utf8mb4 = true;
      trusted_proxies = ["127.0.0.1"];
    };
    maxUploadSize = "2G"; # also sets post_max_size and memory_limit
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.nextcloud = {
    rule = "Host(`nc.firecat53.com`)";
    service = "nextcloud";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.nextcloud = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8082";
        }
      ];
    };
  };
}
