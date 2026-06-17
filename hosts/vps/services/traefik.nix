# Traefik
{
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
    2222 # Forgejo SSH
  ];

  sops.secrets.basic-auth = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  # Porkbun API token for DNS-01 wildcard certs (*.firecat53.com / *.firecat53.me)
  sops.secrets.porkbun-api-keys = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.porkbun-api-keys.path;
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
              certResolver = "le";
              # Default wildcard certs for all routers on this entrypoint.
              domains = [
                {
                  main = "firecat53.com";
                  sans = [ "*.firecat53.com" ];
                }
                {
                  main = "firecat53.me";
                  sans = [ "*.firecat53.me" ];
                }
              ];
            };
          };
        };
        "tcp-2222" = {
          address = ":2222/tcp";
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
            dnsChallenge = {
              provider = "porkbun";
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
            middlewares = [
              "auth"
              "headers"
            ];
            entrypoints = [ "websecure" ];
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
            curvePreferences = [
              "CurveP521"
              "CurveP384"
            ];
          };
        };
      };
    };
  };
}
