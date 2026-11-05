# Nginx
#
# /srv/http (the syncthing "srv" folder) is served on lan.firecat53.net and,
# via the VPS proxy, publicly on firecat53.net and firecat53.com.
let
  site = {
    "= /".extraConfig = ''
      root /srv/http;
      try_files /index.html =404;
    '';
    "/misc/".alias = "/srv/http/";
  };
  mkRouter = host: tls: {
    rule = "Host(`${host}`)";
    service = "nginx";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    inherit tls;
  };
in
{
  services.nginx = {
    enable = true;
    defaultHTTPListenPort = 8080;
    # Relative redirects (e.g. /misc/foo -> /misc/foo/), not to the :8080 listener
    commonHttpConfig = "absolute_redirect off;";
    virtualHosts."lan.firecat53.net".locations = site // {
      "/rss/".alias = "/srv/rss/";
    };
    # /.well-known/matrix/ is routed to continuwuity (matrix-continuwuity.nix)
    virtualHosts."firecat53.net".locations = site // {
      # Everything else (webfinger, host-meta, nodeinfo, old links) is Akkoma's
      "/".return = "301 https://s.firecat53.net$request_uri";
    };
    virtualHosts."firecat53.com".locations = site;
  };
  services.traefik.dynamicConfigOptions.http.routers = {
    nginx = mkRouter "lan.firecat53.net" { certResolver = "le"; };
    nginx-net = mkRouter "firecat53.net" { certResolver = "le"; };
    # TLS ends at the VPS (wildcard cert); this hop only needs some cert
    nginx-com = mkRouter "firecat53.com" { };
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
