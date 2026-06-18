# Single source of truth for VPS-exposed services (*.firecat53.me).
#
# Plain data (no module args) imported by:
#   - proxy-me.nix     generates the *.firecat53.me Traefik routers/services
#   - authelia.nix     derives 2FA-protected domains (auth = true) + access_control rules
#   - uptime-kuma.nix  resolves the homeserver .lan backends (via hsIP)
# Deliberately NOT in services/default.nix, so it is not loaded as a module.
#
# Entry format (fields + full workflow in README, "Adding / removing services"):
#   remote (homeserver):  <sub> = { lan = "<host>.lan.firecat53.net"; auth = <bool>; passHost = <bool>; rules = [ … ]; };
#   local  (VPS):         <sub> = { port = <port>; auth = <bool>; rules = [ … ]; };
# `passHost` and `rules` are optional.
{
  # Homeserver wireguard IP.
  hsIP = "10.200.200.6";

  # Services hosted on the homeserver, reached via its Traefik over wireguard.
  remote = {
    # Public / native-auth (no forward-auth: app & mobile clients need direct API)
    books = {
      lan = "books.lan.firecat53.net";
      auth = false;
      passHost = true;
    };
    git = {
      lan = "git.lan.firecat53.net";
      auth = false;
    };
    hass = {
      lan = "hass.lan.firecat53.net";
      auth = false;
    };
    jellyfin = {
      lan = "jellyfin.lan.firecat53.net";
      auth = false;
    };
    pics = {
      lan = "pics.lan.firecat53.net";
      auth = false;
      passHost = true;
    };
    pix = {
      lan = "pix.lan.firecat53.net";
      auth = false;
    };
    bw = {
      lan = "bw.lan.firecat53.net";
      auth = false;
    };
    # Protected (Authelia two_factor)
    gollum = {
      lan = "gollum.lan.firecat53.net";
      auth = true;
      passHost = true;
    };
    jackett = {
      lan = "jackett.lan.firecat53.net";
      auth = true;
      passHost = true;
    };
    cars = {
      lan = "cars.lan.firecat53.net";
      auth = false;
      passHost = true;
    };
    rss = {
      lan = "rss.lan.firecat53.net";
      auth = false;
      passHost = true;
    };
    radarr = {
      lan = "radarr.lan.firecat53.net";
      auth = true;
      passHost = true;
    };
    sonarr = {
      lan = "sonarr.lan.firecat53.net";
      auth = true;
      passHost = true;
    };
    sabnzbd = {
      lan = "sabnzbd.lan.firecat53.net";
      auth = true;
    };
    qbt = {
      lan = "qbt.lan.firecat53.net";
      auth = true;
    };
    transmission = {
      lan = "transmission.lan.firecat53.net";
      auth = true;
    };
    pdf = {
      lan = "pdf.lan.firecat53.net";
      auth = true;
    };
    today = {
      lan = "today.lan.firecat53.net";
      auth = true;
      passHost = true;
    };
    uph = {
      lan = "up.lan.firecat53.net";
      auth = true;
    };
    syncthing = {
      lan = "syncthing.lan.firecat53.net";
      auth = true;
    };
  };

  # Services hosted locally on the VPS (reached via localhost).
  local = {
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
  };
}
