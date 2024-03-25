# Lidarr
{
  services.lidarr = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/lidarr";
  };
  services.traefik.dynamicConfigOptions.http.routers.lidarr = {
    rule = "Host(`lidarr.lan.firecat53.net`)";
    service = "lidarr";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.lidarr = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8686";
        }
      ];
    };
  };
}
