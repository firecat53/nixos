{
  config,
  ...
}:
{
  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.checkReversePath = "loose"; # Allow tunneling all wireguard traffic
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # Wireguard
  #   To create wireguard connection:
  # `nmcli connection import type wireguard file /etc/wireguard/wg0.conf`
  sops.secrets.wg-private-key = { };
  sops.secrets.wg-preshared-key = { };
  sops.secrets.wg-address = { };
  sops.secrets.wg-allowed-ips = { };
  sops.templates."wg0.conf" = {
    content = ''
      [Interface]
      Address = ${config.sops.placeholder.wg-address}
      ListenPort = 51820
      PrivateKey = ${config.sops.placeholder.wg-private-key}
      DNS = 10.200.200.1

      [Peer]
      # OPNsense
      PublicKey = ADZLBwickizf71ZNv4QpcdFtyHVpe81WnzW8sMPK1Wg=
      PresharedKey = ${config.sops.placeholder.wg-preshared-key}
      AllowedIPs = ${config.sops.placeholder.wg-allowed-ips}
      Endpoint = wg.firecat53.net:51820
      PersistentKeepalive = 25
    '';
    path = "/etc/wireguard/wg0.conf";
  };
  networking.hosts = {
    "10.200.200.2" = [ "laptop" ];
    "10.200.200.4" = [ "backup" ];
    "10.200.200.5" = [ "vps" ];
    "10.200.200.6" = [ "homeserver" ];
    "10.200.200.7" = [ "office" ];
    "10.200.200.10" = [ "jamia" ];
    "10.200.200.12" = [ "janet" ];
    "192.168.200.101" = [ "homeserver" ];
    "192.168.200.102" = [ "hass" ];
    "192.168.200.103" = [ "backup" ];
    "192.168.200.104" = [ "office" ];
  };
}
