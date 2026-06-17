# Single source of truth for VPS-exposed services (*.firecat53.me).
#
# This is plain data (no module args) imported by the modules that need it:
#   - proxy-me.nix     generates the *.firecat53.me Traefik routers/services
#   - authelia.nix     derives the 2FA-protected domain list (auth = true)
#   - uptime-kuma.nix  resolves the homeserver .lan backends (via hsIP)
#
# It is deliberately NOT listed in services/default.nix imports, so it is not
# loaded as a NixOS module.
#
# To expose a new service, add a single entry below — the three consumers all
# update automatically. See README "Adding / removing services and hosts".
{
  # Homeserver wireguard IP. Plan A will later replace this literal with a
  # reference to a central host-topology map.
  hsIP = "10.200.200.6";

  # Services hosted on the homeserver, reached via its Traefik over wireguard.
  #   <me-subdomain> = { lan = <homeserver .lan host>; auth = <gate w/ Authelia>; }
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
    # passHost = true: forward the real *.firecat53.me Host to the backend
    # (default is to send the .lan name). Needed for apps that build absolute
    # redirects/URLs from the Host header; such apps also need a
    # Host(`<sub>.firecat53.me`) router on the homeserver. See README.
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
      auth = true;
    };
    rss = {
      lan = "rss.lan.firecat53.net";
      auth = true;
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
  #   <me-subdomain> = { port = <local port>; auth = <bool>; }
  local = {
    mb = {
      port = 8081;
      auth = true;
    }; # microbin (per-path: viewing is public via Authelia bypass rules, see authelia.nix)
    search = {
      port = 8888;
      auth = true;
    }; # searx
  };
}
