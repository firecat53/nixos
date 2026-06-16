# Audiobookshelf
{
  pkgs,
  ...
}:
{
  services.audiobookshelf = {
    package = pkgs.audiobookshelf;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "audiobookshelf";
  };
  services.traefik.dynamicConfigOptions.http.routers.audiobookshelf = {
    # .me host added so this router matches when the VPS forwards the real
    # public Host (registry passHost = true) for OIDC redirect URIs.
    rule = "Host(`books.lan.firecat53.net`) || Host(`books.firecat53.me`)";
    service = "audiobookshelf";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
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
