# RustDesk ID/rendezvous server (hbbs) and relay server (hbbr)
{ ... }:
{
  services.rustdesk-server = {
    enable = true;
    signal = {
      relayHosts = [ "firecat53.com" ];
      # Reject clients that don't use this server's public key (no unencrypted sessions)
      extraArgs = [
        "-k"
        "_"
      ];
    };
    relay.extraArgs = [
      "-k"
      "_"
    ];
  };

  # openFirewall would also open 21118/21119 (web client), which isn't needed
  networking.firewall.allowedTCPPorts = [
    21115 # hbbs: NAT type test
    21116 # hbbs: ID registration / hole punching
    21117 # hbbr: relay
  ];
  networking.firewall.allowedUDPPorts = [
    21116 # hbbs: ID server
  ];
}
