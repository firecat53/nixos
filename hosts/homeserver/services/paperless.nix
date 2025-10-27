# Paperless-ngx
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.paperless = { };

  # This is the `document_exporter` directory for paperless that should be
  # browseable by anyone in the `users` group without needing paperless running.
  # It's exposed as a Samba share at //homeserver/documents.
  systemd.tmpfiles.rules = [
    "A+ /mnt/documents/paperless/originals - - - - group:users:rX,mask::rX,default:group:users:rX,default:mask::rX"
  ];

  services.paperless = {
    configureTika = true;
    consumptionDir = "/mnt/documents/import";
    consumptionDirIsPublic = true;
    database.createLocally = true;
    dataDir = "/var/lib/paperless";
    enable = true;
    environmentFile = "${config.sops.secrets.paperless.path}";
    exporter = {
      enable = true;
      directory = "/mnt/documents/paperless";
      settings = {
        compare-checksums = true;
        no-archive = true;
        no-progress-bar = true;
        no-thumbnail = true;
        use-folder-prefix = true; # Mount originals at /mnt/documents/paperless/originals
      };
    };
    mediaDir = "/var/lib/paperless/media";
    package = pkgs.paperless-ngx;
    settings = {
      PAPERLESS_URL = "https://docs.lan.firecat53.net";
      PAPERLESS_CONSUMER_RECURSIVE = true;
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.paperless = {
    rule = "Host(`docs.lan.firecat53.net`)";
    service = "paperless";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.paperless = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:28981";
        }
      ];
    };
  };
}
