# akkoma
{
  config,
  pkgs,
  ...
}: {
  services.akkoma = {
    enable = true;
    config = {
      ":pleroma" = {
        ":instance" = {
          name = "firecat53 akkoma";
          email = "scott@firecat53.net";
          description = "Akkoma server";
          registration_open = false;
        };
        "Pleroma.Web.Endpoint" = {
          url.host = "s.firecat53.net";
          http.ip = "127.0.0.1";
          http.port = 4000;
        };
        "Pleroma.Web.WebFinger" = {
          domain = "firecat53.net";
        };
      };
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    middlewares.well-known-redirect.redirectRegex = {
      regex = "^https://(.*)/.well-known/(webfinger|nodeinfo|host-meta)(\\?.*)?$";
      replacement = "https://s.$1/.well-known/$2$3";
      permanent = true;
    };
    routers = {
      akkoma = {
        rule = "Host(`s.firecat53.net`)";
        service = "akkoma";
        middlewares = ["headers"];
        entrypoints = ["websecure"];
        tls.certResolver = "le";
      };
      well-known-redirect = {
        rule = "Host(`firecat53.net`)";
        service = "dummy-well-known";
        middlewares = ["headers" "well-known-redirect"];
        entrypoints = ["websecure"];
        tls.certResolver = "le";
      };
    };
    services = {
      akkoma.loadBalancer.servers = [
        {
          url = "http://localhost:4000";
        }
      ];

      dummy-well-known.loadBalancer.servers = [ {} ];
    };
  };
}
