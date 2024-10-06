{
  config,
  ...
}:{
  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.checkReversePath = "loose";  # Allow tunneling all wireguard traffic
  networking.firewall.allowedUDPPorts = [51820];

  # Wireguard
  #   To create wireguard connection:
  # `nmcli connection import type wireguard file /etc/wireguard/wg0.conf`
  sops.secrets.wg-private-key = {};
  sops.secrets.wg-preshared-key = {};
  sops.secrets.wg-address = {};
  sops.secrets.wg-allowed-ips = {};
  sops.templates."wg0.conf" = {
    content = ''
      [Interface]
      Address = ${config.sops.placeholder.wg-address}
      ListenPort = 51820
      PrivateKey = ${config.sops.placeholder.wg-private-key}
      DNS = 10.200.200.1

      [Peer]
      # pfsense
      PublicKey = gPdBMM+fw4z7XFep7C1WNyLf+jY7433E/RJu+7daJ2w=
      PresharedKey = ${config.sops.placeholder.wg-preshared-key}
      AllowedIPs = ${config.sops.placeholder.wg-allowed-ips}
      Endpoint = wg.firecat53.net:51820
      PersistentKeepalive = 25
    '';
    path = "/etc/wireguard/wg0.conf";
  };
}
