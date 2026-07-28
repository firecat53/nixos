# Single source of truth for services shared between the homeserver and the
# VPS (plus homeserver LAN-only web services).
#
# Plain data (no module args) imported by:
#   homeserver:
#     - services/lan-proxy.nix  generates the *.lan.firecat53.net Traefik
#                               routers/services (+ -me and -noauth companions)
#   vps:
#     - services/proxy-me.nix   generates the *.firecat53.me Traefik routers/services
#     - services/authelia.nix   derives 2FA-protected domains (auth = true) + access_control rules
#     - services/gatus.nix      resolves the homeserver .lan backends (via hsIP)
# Deliberately NOT in either services/default.nix, so it is not loaded as a module.
#
# Entry format (full workflow in README, "Adding / removing services"). Every
# flag controls exactly one generated thing; nothing is derived from another
# flag. The attr name is the *.firecat53.me subdomain (homeserver + vps sets).
#
#   lan       homeserver router host (<name>.lan.firecat53.net) and the backend
#             the VPS proxies to over wireguard  [homeserver/lanOnly]
#   port      backend port on localhost           [homeserver/lanOnly: on the
#             homeserver; vps: on the VPS]
#   url       backend URL; overrides `port` for non-localhost backends
#   auth      true = Authelia 2FA gate on <name>.firecat53.me  [homeserver/vps]
#   passHost  VPS forwards the real *.firecat53.me Host header to the backend
#             instead of the .lan name (apps that build absolute URLs/redirects
#             from Host)                          [homeserver]
#   meRouter  homeserver gets a second router matching <name>.firecat53.me
#             without basicAuth (only the VPS ever sends that host — already
#             2FA'd). Pairs with passHost.        [homeserver]
#   basicAuth homeserver router gets the "auth" basicAuth middleware (auth
#             model: basicAuth on the LAN, Authelia on the internet)
#             [homeserver]
#   vpsBypass homeserver gets a -noauth companion router (ClientIP = vpsIP,
#             priority 100, no basicAuth) so VPS-proxied/Gatus requests skip
#             the basicAuth prompt                [homeserver]
#   rules     per-service Authelia access_control rules  [homeserver/vps]
{
  # Wireguard IPs.
  hsIP = "10.200.200.6"; # homeserver
  vpsIP = "10.200.200.5"; # vps

  # Services hosted on the homeserver, exposed at <name>.lan.firecat53.net by
  # its Traefik and re-exposed at <name>.firecat53.me by the VPS's.
  homeserver = {
    # Public / native-auth (no forward-auth: app & mobile clients need direct API)
    books = {
      # audiobookshelf
      lan = "books.lan.firecat53.net";
      port = 8000;
      auth = false;
      passHost = true;
      meRouter = true;
    };
    git = {
      # forgejo
      lan = "git.lan.firecat53.net";
      port = 3100;
      auth = false;
    };
    hass = {
      # Home Assistant VM
      lan = "hass.lan.firecat53.net";
      url = "http://192.168.200.102:8123";
      auth = false;
    };
    jellyfin = {
      lan = "jellyfin.lan.firecat53.net";
      port = 8096;
      auth = false;
    };
    pics = {
      # immich
      lan = "pics.lan.firecat53.net";
      port = 2283;
      auth = false;
      passHost = true;
      meRouter = true;
    };
    pix = {
      # immich public proxy (public sharing)
      lan = "pix.lan.firecat53.net";
      port = 3030;
      auth = false;
    };
    bw = {
      # vaultwarden
      lan = "bw.lan.firecat53.net";
      port = 8082;
      auth = false;
    };
    # Protected (Authelia two_factor)
    home = {
      # Service dashboard (static site served by nginx, defaultHTTPListenPort)
      lan = "home.lan.firecat53.net";
      port = 8080;
      auth = true;
    };
    gollum = {
      # Gollum builds absolute redirects/URLs from the Host header, so unlike
      # the other basicAuth services it can't rely on the .lan-name + ClientIP
      # trick for VPS traffic: passHost forwards the real gollum.firecat53.me
      # host and meRouter matches it (no basicAuth — that host only ever comes
      # via the VPS, already 2FA'd). LAN/wireguard clients use the .lan router
      # and still get basicAuth. vpsBypass additionally lets the VPS Gatus
      # probe the .lan name (status-code only, so the Host-based absolute URLs
      # don't matter there) — a real outage shows as 502 instead of the auth
      # middleware's 401.
      lan = "gollum.lan.firecat53.net";
      port = 4567;
      auth = true;
      passHost = true;
      meRouter = true;
      basicAuth = true;
      vpsBypass = true;
    };
    jackett = {
      lan = "jackett.lan.firecat53.net";
      port = 9117;
      auth = true;
      passHost = true;
      meRouter = true;
    };
    cars = {
      # lubelogger; passHost so the OAuth Origin/redirect matches
      lan = "cars.lan.firecat53.net";
      port = 5000;
      auth = false;
      passHost = true;
      meRouter = true;
    };
    rss = {
      # miniflux; passHost so the OAuth Origin/redirect matches
      lan = "rss.lan.firecat53.net";
      port = 8085;
      auth = false;
      passHost = true;
      meRouter = true;
    };
    radarr = {
      lan = "radarr.lan.firecat53.net";
      port = 7878;
      auth = true;
      passHost = true;
      meRouter = true;
    };
    sonarr = {
      lan = "sonarr.lan.firecat53.net";
      port = 8989;
      auth = true;
      passHost = true;
      meRouter = true;
    };
    sabnzbd = {
      lan = "sabnzbd.lan.firecat53.net";
      port = 8090;
      auth = true;
    };
    qbt = {
      # qbittorrent (oci-container)
      lan = "qbt.lan.firecat53.net";
      url = "http://127.0.0.1:8081";
      auth = true;
    };
    transmission = {
      # VPS-proxied requests are already 2FA'd by Authelia, so vpsBypass skips
      # the native basicAuth; LAN/wireguard clients still get basicAuth.
      lan = "transmission.lan.firecat53.net";
      port = 9091;
      auth = true;
      basicAuth = true;
      vpsBypass = true;
    };
    pdf = {
      # stirling-pdf
      lan = "pdf.lan.firecat53.net";
      port = 8880;
      auth = true;
    };
    today = {
      # today builds links to the matching gollum host from the request Host
      # header, so (like gollum) it needs the real host: passHost + meRouter.
      # No vpsBypass — VPS traffic arrives as today.firecat53.me and hits the
      # -me router (no basicAuth) already.
      lan = "today.lan.firecat53.net";
      port = 4568;
      auth = true;
      passHost = true;
      meRouter = true;
      basicAuth = true;
    };
    uph = {
      # Gatus monitoring (homeserver instance)
      lan = "up.lan.firecat53.net";
      port = 8083;
      auth = true;
    };
    syncthing = {
      # Same auth model as transmission (see above).
      lan = "syncthing.lan.firecat53.net";
      port = 8384;
      auth = true;
      basicAuth = true;
      vpsBypass = true;
    };
  };

  # Homeserver services only exposed on the LAN — no *.firecat53.me proxy, no
  # Authelia entry; lan-proxy.nix still generates their routers/services.
  lanOnly = {
    yt = {
      # pinchflat
      lan = "yt.lan.firecat53.net";
      port = 8945;
    };
  };

  # Services hosted locally on the VPS (reached via localhost).
  vps = {
    mb = {
      port = 8081;
      auth = true;
      # Keep paste *viewing* public; everything else still requires 2FA.
      rules = [
        {
          policy = "bypass";
          resources = [
            "^/p/.*$"
            "^/upload/[^/]+$" # /upload/{id} view — bare /upload (create) stays gated
            "^/url/.*$"
            "^/u/.*$"
            "^/raw/.*$"
            "^/qr/.*$"
            "^/file/.*$"
            "^/secure_file/.*$"
            "^/archive/.*$"
            "^/auth/.*$"
            "^/auth_raw/.*$"
            "^/auth_file/.*$"
            "^/static/.*$"
            "^/favicon.ico$"
          ];
        }
      ];
    }; # microbin
    search = {
      port = 8888;
      auth = true;
    }; # searx
    prom = {
      port = 9090;
      auth = true;
    }; # prometheus
    alerts = {
      port = 9093;
      auth = true;
    }; # alertmanager
    up = {
      port = 8083;
      auth = true;
    }; # gatus monitoring
  };
}
