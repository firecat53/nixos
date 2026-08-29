# Transmission
{
  networking.firewall.allowedTCPPorts = [ 30020 ];
  networking.firewall.allowedUDPPorts = [ 30020 ];

  services.transmission = {
    enable = true;
    user = "firecat53";
    group = "users";
    openPeerPorts = true;
    settings = {
      watch-dir-enabled = true;
      watch-dir = "/mnt/downloads/blackhole/blackhole-iso";
      rpc-port = 9091;
      rpc-bind-address = "127.0.0.1";
      rpc-host-whitelist-enabled = true;
      rpc-host-whitelist = "transmission.lan.firecat53.net,transmission.firecat53.me";
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1";
      peer-port-random-on-start = false;
      peer-port = 30020;
      incomplete-dir-enabled = true;
      incomplete-dir = "/mnt/downloads/incomplete";
      download-dir = "/mnt/downloads/iso";
    };
  };

  # download/incomplete/watch dirs are all on datapool, and the module BindPaths
  # them into its sandbox at unit start — without this, starting before the
  # mount silently writes torrents to the root pool.
  systemd.services.transmission.unitConfig.RequiresMountsFor = "/mnt/downloads";

  # Traefik routers/service (basicAuth + -noauth companion) generated from the
  # registry (transmission entry) by lan-proxy.nix.
}
