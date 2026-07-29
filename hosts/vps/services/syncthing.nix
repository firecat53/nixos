# Syncthing
{
  pkgs,
  ...
}:
{
  services.syncthing = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/home/firecat53/.config/syncthing";
    configDir = "/home/firecat53/.config/syncthing";
    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      options = {
        relaysEnabled = false;
        urAccepted = 3;
        globalAnnounceServers = [ "https://discover.firecat53.com/" ];
      };
      gui = {
        insecureSkipHostcheck = true;
      };
      devices = {
        "homeserver" = {
          id = "3WS2YZY-BCZNA5N-ZNBCA5G-JNPVFLA-FJQI2VQ-BAM5LK5-UVLWWGM-4DWTRQM";
          addresses = [
            "quic://firecat53.net:22000"
            "tcp://firecat53.net:22000"
          ];
        };
        "scott-laptop" = {
          id = "ERJHQAD-KWQH5ZJ-CAV3ZFL-IR6ECOQ-EHVL7GY-6MY5A5M-IORUVXI-NSBYOQE";
        };
        "scott-office" = {
          id = "4L73OQJ-4T6KOAR-5TJLKKY-ANBRCCB-KAOBFM7-LWVGPFK-QQ643GT-H4LIXAH";
        };
      };
      folders = {
        "srv" = {
          path = "/srv";
          devices = [
            "homeserver"
            "scott-laptop"
            "scott-office"
          ];
        };
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.syncthing = {
    rule = "Host(`syncthing.firecat53.com`)";
    service = "syncthing";
    middlewares = [
      "authelia"
      "headers"
    ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.syncthing = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8384";
        }
      ];
    };
  };
  # Syncthing cli tool stc
  environment.systemPackages = [ pkgs.stc-cli ];
}
