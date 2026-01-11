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
          addresses = [
            "quic://firecat53.net:22000"
            "tcp://firecat53.net:22000"
          ];
        };
        "pangolin" = {
          id = "2IEK3MX-PXVTZIG-D5OP4V3-LYEK3FY-IK4QWIM-K67K65A-ZI62LHH-O3R47Q7";
        };
        "scott-laptop" = {
          id = "ERJHQAD-KWQH5ZJ-CAV3ZFL-IR6ECOQ-EHVL7GY-6MY5A5M-IORUVXI-NSBYOQE";
        };
        "scott-office" = {
          id = "4L73OQJ-4T6KOAR-5TJLKKY-ANBRCCB-KAOBFM7-LWVGPFK-QQ643GT-H4LIXAH";
        };
      };
      folders = {
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = [
            "backup"
            "homeserver"
            "pangolin"
            "scott-laptop"
            "scott-office"
          ];
          id = "smqlq-yhrua";
          type = "receiveonly";
        };
        "shared" = {
          path = "~/shared";
          devices = [
            "homeserver"
            "scott-cell"
            "scott-laptop"
            "scott-office"
          ];
          ignorePerms = true; # Allow ACLs
        };
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
      "auth"
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
