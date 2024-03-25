# Audiobookshelf
{
  pkgs,
  ...
}:{
  services.audiobookshelf = {
    package = pkgs.unstable.audiobookshelf;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "audiobookshelf";
  };
  services.traefik.dynamicConfigOptions.http.routers.audiobookshelf = {
    rule = "Host(`books.lan.firecat53.net`)";
    service = "audiobookshelf";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.audiobookshelf = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8000";
        }
      ];
    };
  };
}
