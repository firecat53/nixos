# Vaultwarden
{
  config,
  pkgs,
  sops,
  ...
}:{
  sops.secrets.vaultwarden-env = {};

  services.vaultwarden = {
    enable = true;
    package = pkgs.unstable.vaultwarden;
    dbBackend = "sqlite";
    config = {
      DOMAIN = "https://bw.lan.firecat53.net";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = "8082";
    };
    environmentFile = "${config.sops.secrets.vaultwarden-env.path}"; 
    backupDir = "/var/lib/bitwarden_rs/backups";
  };

  services.traefik.dynamicConfigOptions.http.routers.vaultwarden = {
    rule = "Host(`bw.lan.firecat53.net`)";
    service = "vaultwarden";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.vaultwarden = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8082";
        }
      ];
    };
  };
}
