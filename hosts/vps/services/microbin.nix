# Microbin
{
  pkgs,
  ...
}:{
  systemd.tmpfiles.rules = [
    "d /var/lib/microbin 0755 firecat53 users -"
  ];
  systemd.services.microbin = {
    enable = true;
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target" "traefik.service"];
    after = ["network-online.target" "traefik.service"];
    serviceConfig = {
      Type = "simple";
      User = "firecat53";
      ExecStart = "${pkgs.unstable.microbin}/bin/microbin";
    };
    environment = {
      #MICROBIN_ADMIN_USERNAME = "firecat53";
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_DATA_DIR = "/var/lib/microbin/";
      MICROBIN_ENABLE_BURN_AFTER = "true";
      MICROBIN_ENABLE_READONLY = "true";
      MICROBIN_ENCRYPTION_CLIENT_SIDE = "true";
      MICROBIN_ENCRYPTION_SERVER_SIDE = "true";
      MICROBIN_HIGHLIGHTSYNTAX = "true";
      MICROBIN_LIST_SERVER = "false";
      MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = "1024";
      MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = "10000";
      MICROBIN_NO_LISTING = "true";
      MICROBIN_PORT = "8081";
      MICROBIN_PRIVATE = "true";
      MICROBIN_PUBLIC_PATH = "https://mb.firecat53.com";
      MICROBIN_QR = "true";
      MICROBIN_READONLY = "true";
      MICROBIN_UPLOADER_PASSWORD = "paced outlying fling exploit";
      MICROBIN_WIDE = "true";
    };
  };

  ## Traefik config
  services.traefik.dynamicConfigOptions.http.routers.microbin = {
    rule = "Host(`mb.firecat53.com`)";
    service = "microbin";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.microbin = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8081";
        }
      ];
    };
  };
}
