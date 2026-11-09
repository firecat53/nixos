# LiveKit SFU + lk-jwt-service: MatrixRTC (Element Call) backend for the
# homeserver's continuwuity (matrix_rtc.foci in matrix-continuwuity.nix).
# Lives on the VPS so media hits a public IP directly, not the wireguard tunnel.
{
  config,
  ...
}:
let
  fqdn = "livekit.firecat53.com";
  jwtPort = 8081; # 8080 is nginx
  router = rule: service: {
    inherit rule service;
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls.certResolver = "le";
  };
  backend = port: {
    loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
  };
in
{
  # "<key>: <secret>", shared by both services
  sops.secrets.livekit-keys = { };

  services.livekit = {
    enable = true;
    keyFile = config.sops.secrets.livekit-keys.path;
    settings = {
      rtc = {
        use_external_ip = true;
        tcp_port = 7881; # fallback for UDP-blocked clients
        enable_loopback_candidate = false;
      };
      room.auto_create = false;
    };
  };

  services.lk-jwt-service = {
    enable = true;
    livekitUrl = "wss://${fqdn}";
    keyFile = config.sops.secrets.livekit-keys.path;
    port = jwtPort;
  };
  # Only local users may create rooms; federated users can still join
  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = "firecat53.net";

  # Not openFirewall: that also exposes 7880, bypassing Traefik
  networking.firewall = {
    allowedTCPPorts = [ config.services.livekit.settings.rtc.tcp_port ];
    allowedUDPPortRanges = [
      {
        from = config.services.livekit.settings.rtc.port_range_start;
        to = config.services.livekit.settings.rtc.port_range_end;
      }
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      livekit = router "Host(`${fqdn}`)" "livekit";
      livekit-jwt = router "Host(`${fqdn}`) && (PathPrefix(`/sfu/get`) || PathPrefix(`/healthz`) || PathPrefix(`/get_token`))" "livekit-jwt";
    };
    services = {
      livekit = backend config.services.livekit.settings.port;
      livekit-jwt = backend jwtPort;
    };
  };
}
