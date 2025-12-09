# Pangolin Proxy Stack with Traefik
{
  config,
  ...
}:
let
  # Configuration variables
  baseDomain = "firecat53.me";
  pangolinHost = "pangolin.${baseDomain}";

  # Docker images
  pangolinImage = "fosrl/pangolin:1.12.3";
  gerbilImage = "fosrl/gerbil:1.3.0";

  # Ports
  apiPort = 3000;
  internalPort = 3001;
  nextPort = 3002;
  gerbilPort = 3004;
  wireguardPort = 51820;
in
{
  # Firewall configuration for WireGuard (HTTP/HTTPS handled by traefik.nix)
  networking.firewall = {
    allowedUDPPorts = [ wireguardPort ];
  };

  sops.secrets = {
    pangolin-secret = { };
  };

  # Create persistent storage directories
  systemd.tmpfiles.rules = [
    "d /var/lib/pangolin 0755 root root -"
    "d /run/pangolin-config 0755 root root -"
    "L+ /run/pangolin-config/config.yml - - - - ${config.sops.templates."pangolin-config.yml".path}"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      pangolin = {
        image = pangolinImage;
        autoStart = true;
        volumes = [
          "/run/pangolin-config/config.yml:/app/config/config.yml:ro"
          "/var/lib/pangolin:/app/config"
        ];
        extraOptions = [
          "--network=host"
          "--health-cmd=curl -f http://localhost:${toString internalPort}/api/v1/"
          "--health-interval=10s"
          "--health-timeout=10s"
          "--health-retries=5"
          # Traefik labels for service discovery
          "--label=traefik.enable=true"
          # Next.js service
          "--label=traefik.http.services.pangolin-next.loadbalancer.server.port=${toString nextPort}"
          "--label=traefik.http.routers.pangolin-next.rule=Host(`${pangolinHost}`) && !PathPrefix(`/api/v1`)"
          "--label=traefik.http.routers.pangolin-next.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-next.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-next.tls.domains[0].main=${baseDomain}"
          "--label=traefik.http.routers.pangolin-next.tls.domains[0].sans=*.${baseDomain}"
          "--label=traefik.http.routers.pangolin-next.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-next.service=pangolin-next"
          # API service
          "--label=traefik.http.services.pangolin-api.loadbalancer.server.port=${toString apiPort}"
          "--label=traefik.http.routers.pangolin-api.rule=Host(`${pangolinHost}`) && PathPrefix(`/api/v1`)"
          "--label=traefik.http.routers.pangolin-api.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-api.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-api.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-api.service=pangolin-api"
          # WebSocket service (uses same backend as API)
          "--label=traefik.http.routers.pangolin-ws.rule=Host(`${pangolinHost}`)"
          "--label=traefik.http.routers.pangolin-ws.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-ws.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-ws.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-ws.service=pangolin-api"
        ];
      };

      gerbil = {
        image = gerbilImage;
        autoStart = true;
        cmd = [
          "--reachableAt=http://localhost:${toString gerbilPort}"
          "--generateAndSaveKeyTo=/var/config/key"
          "--remoteConfig=http://pangolin:${toString internalPort}/api/v1/gerbil/get-config"
          "--reportBandwidthTo=http://pangolin:${toString internalPort}/api/v1/gerbil/receive-bandwidth"
        ];
        volumes = [
          "/var/lib/pangolin/:/var/config"
        ];
        ports = [
          "${toString wireguardPort}:${toString wireguardPort}/udp"
        ];
        extraOptions = [
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=SYS_MODULE"
        ];
        dependsOn = [ "pangolin" ];
      };
    };
  };

  # Template for pangolin config with secret
  sops.templates."pangolin-config.yml" = {
    content = ''
      app:
        dashboard_url: https://${pangolinHost}
        log_level: info
        save_logs: false
      domains:
        domain1:
          base_domain: ${baseDomain}
          cert_resolver: le
      server:
        external_port: ${toString apiPort}
        internal_port: ${toString internalPort}
        next_port: ${toString nextPort}
        internal_hostname: pangolin
        session_cookie_name: p_session_token
        resource_access_token_param: p_token
        resource_session_request_param: p_session_request
        cors:
          origins:
            - https://${pangolinHost}
          methods:
            - GET
            - POST
            - PUT
            - DELETE
            - PATCH
          headers:
            - X-CSRF-Token
            - Content-Type
          credentials: false
        resource_access_token_headers:
          id: P-Access-Token-Id
          token: P-Access-Token
        secret: ${config.sops.placeholder.pangolin-secret}
      traefik:
        cert_resolver: le
        http_entrypoint: web
        https_entrypoint: websecure
      gerbil:
        start_port: ${toString wireguardPort}
        base_endpoint: ${pangolinHost}
        use_subdomain: false
        block_size: 24
        site_block_size: 30
        subnet_group: 100.89.137.0/20
      rate_limits:
        global:
          window_minutes: 1
          max_requests: 500
      flags:
        require_email_verification: false
        disable_signup_without_invite: true
        disable_user_create_org: false
        allow_raw_resources: true
        allow_base_domain_resources: true
        prefer_wildcard_cert: true
    '';
    mode = "0440";
    owner = "root";
    group = "root";
  };

  # Ensure gerbil starts after pangolin
  systemd.services.podman-gerbil = {
    after = [ "podman-pangolin.service" ];
    requires = [ "podman-pangolin.service" ];
  };
}
