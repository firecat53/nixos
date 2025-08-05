{
  config,
  ...
}:
let
  externalServers = [ "vps" ]; # Add server names to list that are not in the LAN

  wgEndpoint =
    if builtins.elem config.networking.hostName externalServers then
      "wg.firecat53.net:51820"
    else
      "192.168.200.1:51820";
in
{
  # Wireguard systemd-networkd
  networking.firewall.checkReversePath = "loose"; # Allow tunneling all wireguard traffic
  networking.firewall.allowedUDPPorts = [ 51820 ];

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
            # Opnsense
            PublicKey = "ADZLBwickizf71ZNv4QpcdFtyHVpe81WnzW8sMPK1Wg=";
            PresharedKeyFile = "${config.sops.secrets.wg-preshared-key.path}";
            AllowedIPs = [ "10.200.200.0/24" ];
            Endpoint = wgEndpoint;
          }
        ];
      };
    };
    networks.wg0 = {
      matchConfig.Name = "wg0";
      #address = ["10.200.200.6/32"]; Set in configuration.nix for each host
      DHCP = "no";
      dns = [ "10.200.200.1" ];
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPv4Forwarding = "yes";
      };
    };
  };
}
