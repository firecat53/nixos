# Traefik
{
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  sops.secrets.basic-auth = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  # Add traefik user to podman group for socket access
  users.users.traefik.extraGroups = [ "podman" ];

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      serversTransport = {
        insecureSkipVerify = true;
      };
      ping = {
        entryPoint = "web";
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
          transport = {
            respondingTimeouts = {
              readTimeout = "30m";
            };
          };
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
      log = {
        level = "INFO";
        format = "common";
      };
      providers = {
        docker = {
          endpoint = "unix:///run/podman/podman.sock";
          exposedByDefault = false;
        };
        http = {
          endpoint = "http://localhost:3001/api/v1/traefik-config";
          pollInterval = "5s";
        };
      };
      # Experimental plugins for Pangolin
      experimental = {
        plugins = {
          badger = {
            moduleName = "github.com/fosrl/badger";
            version = "v1.2.1";
          };
        };
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
            rule = "Host(`monitor.firecat53.me`)";
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
              sslhost = "firecat53.me";
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
            curvePreferences = [
              "CurveP521"
              "CurveP384"
            ];
          };
        };
      };
    };
  };
  systemd.services.traefik.serviceConfig.WorkingDirectory = "/var/lib/traefik";
}
