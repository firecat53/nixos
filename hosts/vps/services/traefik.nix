# Traefik
{
  config,
  sops,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443];

  sops.secrets.basic-auth = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      serversTransport = {
        insecureSkipVerify = true;
      };
      entryPoints = {
        web = {
          address = ":80";
          http = {
            redirections = {
              entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
          };
        };
        websecure = {
          address = ":443";
          http = {
            tls = {
              options = "default";
            };
          };
        };
      };
      api = {
        dashboard = true;
      };
      certificatesResolvers = {
        le = {
          acme = {
            email = "tech@firecat53.net";
            storage = "/var/lib/traefik/acme.json";
            httpChallenge = {
              entryPoint = "web";
            };
          };
        };
      };
    };
    dynamicConfigOptions = {
      http = {
        routers = {
          dashboard = {
            rule = "Host(`monitor.firecat53.com`)";
            service = "api@internal";
            middlewares = ["auth" "headers"];
            entrypoints = ["websecure"];
            tls = {
              certResolver = "le";
            };
          };
        };
        middlewares = {
          auth = {
            basicAuth = {
              usersFile = "${config.sops.secrets.basic-auth.path}";
            };
          };
          headers = {
            headers = {
              browserxssfilter = true;
              contenttypenosniff = true;
              customframeoptionsvalue = "SAMEORIGIN";
              forcestsheader = true;
              framedeny = true;
              sslhost = "firecat53.com";
              sslredirect = true;
              stsincludesubdomains = true;
              stspreload = true;
              stsseconds = "315360000";
            };
          };
        };
      };
      tls = {
        options = {
          default = {
            minVersion = "VersionTLS13";
            sniStrict = true;
            curvePreferences = ["CurveP521" "CurveP384"];
          };
        };
      };
    };
  };
}
