# Nginx
{
  services.nginx = {
    enable = true;
    defaultHTTPListenPort = 8080;
    virtualHosts."lan.firecat53.net" = {
      locations."/misc/" = {
        alias = "/srv/http/";
      };
      locations."/rss/" = {
        alias = "/srv/rss/";
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.nginx = {
    rule = "Host(`lan.firecat53.net`) && ((PathPrefix(`/misc`) || PathPrefix(`/rss`)))";
    service = "nginx";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.nginx = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8080";
        }
      ];
    };
  };
}
