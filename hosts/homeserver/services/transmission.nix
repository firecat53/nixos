# Transmission
{
  networking.firewall.allowedTCPPorts = [30020];
  networking.firewall.allowedUDPPorts = [30020];

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
      rpc-host-whitelist = "transmission.lan.firecat53.net";
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1";
      peer-port-random-on-start = false;
      peer-port = 30020;
      incomplete-dir-enabled = true;
      incomplete-dir = "/mnt/downloads/incomplete";
      download-dir = "/mnt/downloads/iso";
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.transmission = {
    rule = "Host(`transmission.lan.firecat53.net`)";
    service = "transmission";
    middlewares = ["auth" "headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.transmission = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:9091";
        }
      ];
    };
  };
}
