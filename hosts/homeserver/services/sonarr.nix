# Sonarr
{
  services.sonarr = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/sonarr";
  };
  services.traefik.dynamicConfigOptions.http.routers.sonarr = {
    rule = "Host(`sonarr.lan.firecat53.net`)";
    service = "sonarr";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.sonarr = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8989";
        }
      ];
    };
  };
}
