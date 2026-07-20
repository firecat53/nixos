# Gatus - declarative status/health monitoring
#
# Probing strategy:
#   - Homeserver apps are probed over the wireguard tunnel by hitting the
#     homeserver's Traefik (10.200.200.6) with their `*.lan.firecat53.net` Host
#     header. Those names already resolve to the homeserver on this host via
#     proxy-me.nix (networking.hosts), so we reuse them here. This bypasses
#     Authelia (the VPS-only forward-auth) and tests the real backend + the
#     homeserver's valid Let's Encrypt certs (cert-expiry conditions included).
#   - Akkoma and Matrix are NOT in the registry and are federated/public
#     services, so they are probed via their real public endpoints end-to-end.
#
# Served behind Authelia at gatus.firecat53.me (service-registry.nix `vps` entry,
# auth = true -> router + forward-auth wired by proxy-me.nix / authelia.nix).
#
{
  config,
  lib,
  ...
}:
let
  # Homeserver wireguard IP (single source of truth in service-registry.nix)
  inherit (import ../../modules/service-registry.nix) hsIP;

  # Matrix alert room internal id. NOT a secret (just an identifier, useless
  # without the access token + room membership)
  matrixRoomId = "!KpLUPKbxnaqAQdTnqG:firecat53.net";

  # Alert every endpoint to Matrix. Tunables: confirm down after 3 failed
  # checks, resolved after 2 successes, and notify on recovery.
  matrixAlerts = [
    {
      type = "matrix";
      "failure-threshold" = 3;
      "success-threshold" = 2;
      "send-on-resolved" = true;
    }
  ];

  # Add secondary email notifier for more critical items (traefik, matrix, etc)
  matrixAndEmail = matrixAlerts ++ [
    {
      type = "email";
      "failure-threshold" = 3;
      "success-threshold" = 2;
      "send-on-resolved" = true;
    }
  ];

  # Warn when a cert has < 7 days (168h) left.
  certOk = "[CERTIFICATE_EXPIRATION] > 168h";

  # HTTP endpoint helper. `client` is an optional Gatus client config (e.g.
  # { "ignore-redirect" = true; }).
  ep =
    {
      name,
      group ? "homeserver",
      url,
      conditions,
      client ? null,
      alerts ? matrixAlerts,
    }:
    {
      inherit
        name
        group
        url
        conditions
        alerts
        ;
      interval = "1m";
    }
    // lib.optionalAttrs (client != null) { inherit client; };

  # TCP endpoint helper (Samba, socks proxy).
  tcp = name: url: {
    inherit name url;
    group = "network";
    interval = "1m";
    conditions = [ "[CONNECTED] == true" ];
    alerts = matrixAlerts;
  };

  ok200 = [
    "[STATUS] == 200"
    certOk
  ];
in
{
  # --- Matrix alert token (sops) -------------------------------------------
  sops.secrets.gatus-matrix-token = { };
  sops.templates."gatus.env".content = ''
    MATRIX_ACCESS_TOKEN=${config.sops.placeholder.gatus-matrix-token}
    SMTP_PASSWORD=${config.sops.placeholder.email-password}
  '';

  # Resolve the homeserver Traefik dashboard name over wireguard.
  networking.hosts.${hsIP} = [ "monitor.lan.firecat53.net" ];

  services.gatus = {
    enable = true;
    environmentFile = config.sops.templates."gatus.env".path;
    settings = {
      web.port = 8083;
      ui = {
        title = "firecat53 status";
        header = "Homeserver Status";
        "default-sort-by" = "health";
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };

      alerting.matrix = {
        "server-url" = "https://matrix.firecat53.net";
        "internal-room-id" = matrixRoomId;
        "access-token" = "\${MATRIX_ACCESS_TOKEN}";
      };

      # Secondary notifier (see matrixAndEmail).
      alerting.email = {
        from = "noreply@firecat53.net";
        username = "scott@firecat53.net";
        password = "\${SMTP_PASSWORD}";
        host = "smtp.fastmail.com";
        port = 587;
        to = "tech@firecat53.net";
      };

      endpoints = [
        # --- Federated / public (probed end-to-end, real public DNS) ------
        (ep {
          name = "akkoma";
          group = "public";
          url = "https://s.firecat53.net/api/v1/instance";
          conditions = ok200;
        })
        (ep {
          name = "matrix";
          group = "public";
          url = "https://matrix.firecat53.net/_matrix/federation/v1/version";
          conditions = ok200;
          alerts = matrixAndEmail;
        })

        # --- Media --------------------------------------------------------
        (ep {
          name = "jellyfin";
          group = "media";
          url = "https://jellyfin.lan.firecat53.net/health";
          conditions = ok200; # /health returns "Healthy"
        })
        (ep {
          name = "immich";
          group = "media";
          url = "https://pics.lan.firecat53.net/api/server/ping";
          conditions = ok200; # returns {"res":"pong"}
        })
        (ep {
          name = "audiobookshelf";
          group = "media";
          url = "https://books.lan.firecat53.net/healthcheck";
          conditions = ok200;
        })

        # --- Downloads / *arr --------------------------------------------
        (ep {
          name = "radarr";
          group = "downloads";
          url = "https://radarr.lan.firecat53.net/ping";
          conditions = ok200; # {"status":"OK"}
        })
        (ep {
          name = "sonarr";
          group = "downloads";
          url = "https://sonarr.lan.firecat53.net/ping";
          conditions = ok200;
        })
        (ep {
          name = "jackett";
          group = "downloads";
          url = "https://jackett.lan.firecat53.net/";
          # Jackett 301-redirects every path, and following the chain dead-ends
          # at 400. Don't follow redirects: the 301 itself proves Jackett is up;
          # a real outage surfaces as a 502/503/504 from Traefik.
          client."ignore-redirect" = true;
          conditions = [
            "[STATUS] == any(301, 302)"
            certOk
          ];
        })
        (ep {
          name = "sabnzbd";
          group = "downloads";
          url = "https://sabnzbd.lan.firecat53.net/";
          conditions = [
            "[STATUS] == any(200, 401, 403)"
            certOk
          ];
        })
        (ep {
          name = "qbittorrent";
          group = "downloads";
          url = "https://qbt.lan.firecat53.net/";
          conditions = [
            "[STATUS] == any(200, 401, 403)"
            certOk
          ];
        })
        (ep {
          name = "transmission";
          group = "downloads";
          url = "https://transmission.lan.firecat53.net/transmission/web/";
          # VPS (10.200.200.5) hits the transmission-noauth bypass -> backend.
          conditions = ok200;
        })

        # --- Apps ---------------------------------------------------------
        (ep {
          name = "forgejo";
          group = "apps";
          url = "https://git.lan.firecat53.net/api/healthz";
          conditions = ok200;
        })
        (ep {
          name = "miniflux";
          group = "apps";
          url = "https://rss.lan.firecat53.net/healthcheck";
          conditions = ok200; # returns "OK"
        })
        (ep {
          name = "vaultwarden";
          group = "apps";
          url = "https://bw.lan.firecat53.net/alive";
          conditions = ok200;
        })
        (ep {
          name = "syncthing";
          group = "apps";
          url = "https://syncthing.lan.firecat53.net/rest/noauth/health";
          conditions = ok200; # {"status":"OK"}, no auth required
        })
        (ep {
          name = "home-assistant";
          group = "apps";
          url = "https://hass.lan.firecat53.net/";
          conditions = [
            "[STATUS] == any(200, 302)"
            certOk
          ];
        })
        (ep {
          name = "gollum";
          group = "apps";
          url = "https://gollum.lan.firecat53.net/";
          # VPS (10.200.200.5) hits the gollum-noauth bypass router, so the
          # probe reaches the backend: 200 = up, 502 = down.
          conditions = ok200;
        })
        (ep {
          name = "lubelogger";
          group = "apps";
          url = "https://cars.lan.firecat53.net/";
          conditions = [
            "[STATUS] == any(200, 302)"
            certOk
          ];
        })
        (ep {
          name = "stirling-pdf";
          group = "apps";
          url = "https://pdf.lan.firecat53.net/";
          conditions = [
            "[STATUS] == any(200, 302)"
            certOk
          ];
        })

        # --- Infra --------------------------------------------------------
        (ep {
          name = "traefik";
          group = "infra";
          url = "https://monitor.lan.firecat53.net/";
          # Dashboard is behind basic auth -> 401 proves Traefik + middleware up.
          conditions = [
            "[STATUS] == 401"
            certOk
          ];
          alerts = matrixAndEmail;
        })

        # --- Network (raw TCP) -------------------------------------------
        (tcp "samba" "tcp://${hsIP}:445")
        (tcp "socks-proxy" "tcp://${hsIP}:2222")
      ];
    };
  };
}
