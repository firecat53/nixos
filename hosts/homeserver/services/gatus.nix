# Gatus - declarative status/health monitoring
#
#   - VPS apps with a public *.firecat53.com endpoint that is NOT behind
#     Authelia (grafana, nextcloud, nginx, apparatus) are probed end-to-end over
#     their real public URL. That tests DNS + the VPS Traefik + the wildcard
#     cert (cert-expiry conditions included) + the backend in one shot.
#   - Microbin lives behind Authelia at mb.firecat53.me, but paste assets are
#     bypassed (see registry.nix `mb.rules`), so /favicon.ico reaches the
#     microbin backend directly and proves it is up.
#   - Prometheus and Alertmanager are Authelia-gated on the public side, so they
#     are probed directly over the wireguard tunnel on their backend ports
#     (the VPS trusts wg0, so 0.0.0.0-bound services are reachable at 10.200.200.5).
#   - Syncthing (VPS + backup) are checked with a raw TCP probe of their sync
#     ports. The Omada controller is probed over HTTPS (self-signed cert ->
#     insecure, no cert-expiry assertion); a 200/302 means the UI is responding.
{
  config,
  lib,
  ...
}:
let
  # VPS wireguard IP.
  vpsIP = "10.200.200.5";
  # LAN hosts.
  backupIP = "192.168.200.103"; # syncthing on the backup host
  hassIP = "192.168.200.102"; # Omada controller runs in the Home Assistant VM

  # Matrix alert room internal id.
  matrixRoomId = "!KpLUPKbxnaqAQdTnqG:firecat53.net";

  # Alert every endpoint to Matrix. Confirm down after 3 failed checks, resolved
  # after 2 successes, notify on recovery.
  matrixAlerts = [
    {
      type = "matrix";
      "failure-threshold" = 3;
      "success-threshold" = 2;
      "send-on-resolved" = true;
    }
  ];

  # Add a secondary email notifier for critical infra (Traefik) if Matrix is down
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

  # HTTP endpoint helper. `client` is an optional Gatus client config.
  ep =
    {
      name,
      group ? "vps",
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

  # TCP endpoint helper.
  tcp =
    {
      name,
      url,
      group ? "network",
    }:
    {
      inherit name url group;
      interval = "1m";
      conditions = [ "[CONNECTED] == true" ];
      alerts = matrixAlerts;
    };

  # HTTPS (public) -> status + cert expiry. HTTP (over wg) -> status only.
  ok200 = [
    "[STATUS] == 200"
    certOk
  ];
  status200 = [ "[STATUS] == 200" ];
in
{
  sops.secrets.gatus-matrix-token = { };
  sops.templates."gatus.env".content = ''
    MATRIX_ACCESS_TOKEN=${config.sops.placeholder.gatus-matrix-token}
    SMTP_PASSWORD=${config.sops.placeholder.email-password}
  '';

  services.gatus = {
    enable = true;
    environmentFile = config.sops.templates."gatus.env".path;
    settings = {
      web.port = 8083;
      ui = {
        title = "firecat53 status";
        header = "VPS / Remote Status";
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
        (ep {
          name = "grafana";
          url = "https://grafana.firecat53.com/api/health";
          conditions = ok200; # {"database":"ok",...}
        })
        (ep {
          name = "nextcloud";
          url = "https://nc.firecat53.com/status.php";
          conditions = ok200; # {"installed":true,...}, no auth
        })
        (ep {
          name = "nginx";
          url = "https://firecat53.com/misc/";
          conditions = ok200;
        })
        (ep {
          name = "apparatus";
          url = "https://bfd.firecat53.com/api/health";
          conditions = ok200; # pocketbase {"code":200,...}
        })
        (ep {
          name = "microbin";
          url = "https://mb.firecat53.me/favicon.ico";
          # /favicon.ico is in microbin's Authelia bypass list (registry.nix
          # mb.rules), so a 200 here comes from the microbin backend itself.
          conditions = ok200;
        })

        # --- VPS infra (probed over wireguard, Authelia-gated publicly) ---
        (ep {
          name = "prometheus";
          group = "infra";
          url = "http://${vpsIP}:9090/-/healthy";
          conditions = status200;
        })
        (ep {
          name = "alertmanager";
          group = "infra";
          url = "http://${vpsIP}:9093/-/healthy";
          conditions = status200;
        })
        (ep {
          name = "traefik";
          group = "infra";
          url = "https://monitor.firecat53.com/";
          # Dashboard is behind basic auth -> 401 proves Traefik + middleware up.
          conditions = [
            "[STATUS] == 401"
            certOk
          ];
          alerts = matrixAndEmail;
        })

        # --- Syncthing / LAN devices (raw TCP) ---------------------------
        (tcp {
          name = "syncthing-vps";
          url = "tcp://${vpsIP}:22000";
        })
        (tcp {
          name = "syncthing-backup";
          url = "tcp://${backupIP}:22000";
        })
        (ep {
          name = "omada";
          group = "network";
          url = "https://${hassIP}:8043/";
          # Self-signed cert -> skip verification and don't assert cert expiry.
          # The controller 302-redirects to its login path when healthy.
          client.insecure = true;
          conditions = [ "[STATUS] == any(200, 302)" ];
        })
      ];
    };
  };

  # Served at up.lan.firecat53.net (re-exposed at uph.firecat53.me by the VPS);
  # Traefik routers/service generated from the registry (uph entry) by lan-proxy.nix.
}
