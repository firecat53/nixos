# Nextcloud
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.nextcloud-admin-password = { };
  users.users.nextcloud.extraGroups = [
    "users"
    "msmtp"
  ];
  services.nginx.virtualHosts."nc.firecat53.com".listen = [
    {
      addr = "127.0.0.1";
      port = 8082;
    }
  ];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
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
      trusted_proxies = [ "127.0.0.1" ];
    };
    maxUploadSize = "2G"; # also sets post_max_size and memory_limit
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
    };
  };

  systemd.services.nextcloud-setup.serviceConfig = {
    LoadCredential = [
      "email-password:${config.sops.secrets.email-password.path}"
    ];
  };

  services.traefik.dynamicConfigOptions.http.routers.nextcloud = {
    rule = "Host(`nc.firecat53.com`)";
    service = "nextcloud";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
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
