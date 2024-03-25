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
  sops.secrets.cf-api-token = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  systemd.services.traefik.environment = {
    CF_DNS_API_TOKEN_FILE = "${config.sops.secrets.cf-api-token.path}"; 
  };
  users.users.traefik.extraGroups = ["podman"];
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
      providers = {
        docker = {
          endpoint = "unix:///var/run/podman/podman.sock";
          exposedByDefault = false;
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
              provider = "cloudflare";
              resolvers = ["1.1.1.1:53"];
            };
          };
        };
      };
    };
    dynamicConfigOptions = {
      http = {
        routers = {
          dashboard = {
            rule = "Host(`monitor.lan.firecat53.net`)";
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
