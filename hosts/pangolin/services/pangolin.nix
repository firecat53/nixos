# Pangolin Proxy Stack with Traefik
{
  config,
  ...
}:
{
  # Firewall configuration for WireGuard (HTTP/HTTPS handled by traefik.nix)
  networking.firewall = {
    allowedUDPPorts = [ 51820 ]; # Wireguard
  };

  # Sops secrets
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
        image = "fosrl/pangolin:1.12.2";
        autoStart = true;
        volumes = [
          "/run/pangolin-config/config.yml:/app/config/config.yml:ro"
          "/var/lib/pangolin:/app/config"
        ];
        extraOptions = [
          "--network=host"
          "--health-cmd=curl -f http://localhost:3001/api/v1/"
          "--health-interval=10s"
          "--health-timeout=10s"
          "--health-retries=5"
          # Traefik labels for service discovery
          "--label=traefik.enable=true"
          # Next.js service
          "--label=traefik.http.services.pangolin-next.loadbalancer.server.port=3002"
          "--label=traefik.http.routers.pangolin-next.rule=Host(`pangolin.firecat53.me`) && !PathPrefix(`/api/v1`)"
          "--label=traefik.http.routers.pangolin-next.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-next.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-next.tls.domains[0].main=firecat53.me"
          "--label=traefik.http.routers.pangolin-next.tls.domains[0].sans=*.firecat53.me"
          "--label=traefik.http.routers.pangolin-next.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-next.service=pangolin-next"
          # API service
          "--label=traefik.http.services.pangolin-api.loadbalancer.server.port=3000"
          "--label=traefik.http.routers.pangolin-api.rule=Host(`pangolin.firecat53.me`) && PathPrefix(`/api/v1`)"
          "--label=traefik.http.routers.pangolin-api.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-api.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-api.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-api.service=pangolin-api"
          # WebSocket service (uses same backend as API)
          "--label=traefik.http.routers.pangolin-ws.rule=Host(`pangolin.firecat53.me`)"
          "--label=traefik.http.routers.pangolin-ws.entrypoints=websecure"
          "--label=traefik.http.routers.pangolin-ws.tls.certResolver=le"
          "--label=traefik.http.routers.pangolin-ws.middlewares=headers@file"
          "--label=traefik.http.routers.pangolin-ws.service=pangolin-api"
        ];
      };

      gerbil = {
        image = "fosrl/gerbil:1.2.2";
        autoStart = true;
        cmd = [
          "--reachableAt=http://localhost:3004"
          "--generateAndSaveKeyTo=/var/config/key"
          "--remoteConfig=http://localhost:3001/api/v1/gerbil/get-config"
          "--reportBandwidthTo=http://localhost:3001/api/v1/gerbil/receive-bandwidth"
        ];
        volumes = [
          "/var/lib/pangolin/:/var/config"
        ];
        ports = [
          "51820:51820/udp"
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
        dashboard_url: https://pangolin.firecat53.me
        log_level: info
        save_logs: false
      domains:
        domain1:
          base_domain: firecat53.me
          cert_resolver: le
      server:
        external_port: 3000
        internal_port: 3001
        next_port: 3002
        internal_hostname: pangolin
        session_cookie_name: p_session_token
        resource_access_token_param: p_token
        resource_session_request_param: p_session_request
        cors:
          origins:
            - https://pangolin.firecat53.me
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
        start_port: 51820
        base_endpoint: pangolin.firecat53.me
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
