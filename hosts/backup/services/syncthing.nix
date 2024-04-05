# Syncthing
{
  lib,
  ...
}:{
  services.syncthing = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/home/firecat53/.local/state/syncthing";
    configDir = "/home/firecat53/.config/syncthing";
    openDefaultPorts = true;
    settings = {
      gui = {
        insecureSkipHostcheck = true;
      };
      options = {
        relaysEnabled = false;
        urAccepted = 3;
      };
      devices = {
        "vps" = {
          id = "EPFW7TB-MUV25YB-P2SM66L-ENLRREJ-UJIRELD-QC2FWM4-RVSLFJY-7YWXCQ6";
          addresses = ["quic://firecat53.com:22000" "tcp://firecat53.com:22000"];
        };
        "scott-laptop" = {
          id = "ERJHQAD-KWQH5ZJ-CAV3ZFL-IR6ECOQ-EHVL7GY-6MY5A5M-IORUVXI-NSBYOQE";
        };
        "scott-office" = {
          id = "JJEHDJM-7EXVS6I-U5LIV3G-QH56XUA-77WXQZA-PXI4GIF-6ATNTOZ-5JA2FQV";
        };
        "homeserver" = {
          id = "3WS2YZY-BCZNA5N-ZNBCA5G-JNPVFLA-FJQI2VQ-BAM5LK5-UVLWWGM-4DWTRQM";
        };
      };
      folders = {
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = ["scott-laptop" "scott-office" "homeserver" "vps"];
          id = "smqlq-yhrua";
          type = "receiveonly";
        };
      };
    };
  };
}
