# Nginx
{
  ## Create/chown needed files/directories
  systemd.tmpfiles.rules = [
    "d /srv/ 0755 firecat53 users -"
  ];

  services.nginx = {
    enable = true;
    defaultHTTPListenPort = 8080;
    virtualHosts."firecat53.com" = {
      locations."/misc/" = {
        alias = "/srv/http/";
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.nginx = {
    rule = "Host(`firecat53.com`) && PathPrefix(`/`)";
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
