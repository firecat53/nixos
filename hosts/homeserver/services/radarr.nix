# Radarr
{
  pkgs,
  ...
}:{
  services.radarr = {
    package = pkgs.unstable.radarr;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/radarr";
  };
  services.traefik.dynamicConfigOptions.http.routers.radarr = {
    rule = "Host(`radarr.lan.firecat53.net`)";
    service = "radarr";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.radarr = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:7878";
        }
      ];
    };
  };
}
