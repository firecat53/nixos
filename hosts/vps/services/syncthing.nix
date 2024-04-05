# Syncthing
{
  lib,
  ...
}:{
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
      };
      gui = {
        insecureSkipHostcheck = true;
      };
      devices = {
        "backup" = {
          id = "CAKABE3-JTNUTY6-6BJYHGS-7E4Z35Y-SDF5M6H-GLB6Q2G-M6FVISW-Q3AVHQV";
        };
        "scott-cell" = {
          id = "6LDX7IF-D2MWKOW-APU3AUX-WXNBWFG-PNIUAPB-QKTWZHF-7MKLPBI-M6E6AQE";
        };
        "homeserver" = {
          id = "3WS2YZY-BCZNA5N-ZNBCA5G-JNPVFLA-FJQI2VQ-BAM5LK5-UVLWWGM-4DWTRQM";
          addresses = ["quic://firecat53.net:22000" "tcp://firecat53.net:22000"];
        };
        "scott-laptop" = {
          id = "ERJHQAD-KWQH5ZJ-CAV3ZFL-IR6ECOQ-EHVL7GY-6MY5A5M-IORUVXI-NSBYOQE";
        };
        "scott-office" = {
          id = "JJEHDJM-7EXVS6I-U5LIV3G-QH56XUA-77WXQZA-PXI4GIF-6ATNTOZ-5JA2FQV";
        };
      };
      folders = {
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = ["homeserver" "scott-laptop" "backup" "scott-office"];
          id = "smqlq-yhrua";
          type = "receiveonly";
        };
        "shared" = {
          path = "~/shared";
          devices = ["scott-cell" "homeserver" "scott-laptop" "scott-office"];
        };
        "srv" = {
          path = "/srv";
          devices = ["homeserver" "scott-laptop" "scott-office"];
        };
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.syncthing = {
    rule = "Host(`syncthing.firecat53.com`)";
    service = "syncthing";
    middlewares = ["auth" "headers"];
    entrypoints = ["websecure"];
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
}
