# Syncthing
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
        "vps" = {
          id = "EPFW7TB-MUV25YB-P2SM66L-ENLRREJ-UJIRELD-QC2FWM4-RVSLFJY-7YWXCQ6";
          addresses = [
            "quic://firecat53.com:22000"
            "tcp://firecat53.com:22000"
          ];
        };
      };
      folders = {
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = [
            "homeserver"
            "scott-laptop"
            "scott-office"
            "vps"
          ];
          id = "smqlq-yhrua";
          type = "receiveonly";
        };
      };
    };
  };
}
