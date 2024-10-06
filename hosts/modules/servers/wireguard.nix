{
  config,
  sops,
  ...
}:{
  # Wireguard systemd-networkd
  networking.firewall.checkReversePath = "loose";  # Allow tunneling all wireguard traffic
  networking.firewall.allowedUDPPorts = [51820];

  sops.secrets.wg-private-key = {
    owner = "systemd-network";
  };
  sops.secrets.wg-preshared-key = {
    owner = "systemd-network";
  };
  systemd.network = {
    enable = true;
    netdevs = {
      "10-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          # Must be readable by the systemd.network user
          PrivateKeyFile = "${config.sops.secrets.wg-private-key.path}";
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # Pfsense
              PublicKey = "gPdBMM+fw4z7XFep7C1WNyLf+jY7433E/RJu+7daJ2w=";
              PresharedKeyFile = "${config.sops.secrets.wg-preshared-key.path}";
              AllowedIPs = ["10.200.200.1/24"];
              Endpoint = "wg.firecat53.net:51820";
            };
          }
        ];
      };
    };
    networks.wg0 = {
      matchConfig.Name = "wg0";
      #address = ["10.200.200.6/32"]; Set in configuration.nix for each host
      DHCP = "no";
      dns = ["10.200.200.1"];
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPForward = "yes";
      };
    };
  };
}
