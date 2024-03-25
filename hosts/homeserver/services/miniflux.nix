# Miniflux
{
  config,
  sops,
  ...
}:{
  sops.secrets.miniflux-env = {};
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "localhost:8085";
      POLLING_FREQUENCY = "15";
      RUN_MIGRATIONS = "1";
    };
    adminCredentialsFile = "${config.sops.secrets.miniflux-env.path}";
  };

  services.traefik.dynamicConfigOptions.http.routers.miniflux = {
    rule = "Host(`rss.lan.firecat53.net`)";
    service = "miniflux";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.miniflux = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8085";
        }
      ];
    };
  };
}
