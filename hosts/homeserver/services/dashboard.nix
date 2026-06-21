# Service dashboard - grouped cards linking to services on the homeserver and
# (vps). Static site (see pkgs/dashboard) served by nginx at:
#   - home.lan.firecat53.net and home.firecat53.me
{
  pkgs,
  ...
}:
let
  localPkgs = import ../../../pkgs { inherit pkgs; };

  # registry.nix is the single source of truth for *.firecat53.me subdomains.
  # `me` builds the public URL and asserts the subdomain is actually exposed,
  # so removing a service from the registry breaks the build instead of leaving
  # a dead tile.
  reg = import ../../vps/services/registry.nix;
  meSubs = (builtins.attrNames reg.remote) ++ (builtins.attrNames reg.local);
  me =
    sub:
    assert lib.assertMsg (builtins.elem sub meSubs)
      "dashboard: '${sub}' is not a registered *.firecat53.me service";
    "https://${sub}.firecat53.me";
  lib = pkgs.lib;

  groups = [
    {
      name = "Media";
      items = [
        {
          label = "Audiobookshelf";
          url = me "books";
          icon = "audiobookshelf.svg";
        }
        {
          label = "Immich";
          url = me "pics";
          icon = "immich.svg";
        }
        {
          label = "Jackett";
          url = me "jackett";
          icon = "jackett.svg";
        }
        {
          label = "Jellyfin";
          url = me "jellyfin";
          icon = "jellyfin.svg";
        }
        {
          label = "Pinchflat";
          url = "https://yt.lan.firecat53.net"; # LAN only (not exposed at .me)
          icon = "pinchflat.png";
        }
        {
          label = "qBittorrent";
          url = me "qbt";
          icon = "qbittorrent.svg";
        }
        {
          label = "Radarr";
          url = me "radarr";
          icon = "radarr.svg";
        }
        {
          label = "SABnzbd";
          url = me "sabnzbd";
          icon = "sabnzbd.svg";
        }
        {
          label = "Sonarr";
          url = me "sonarr";
          icon = "sonarr.svg";
        }
        {
          label = "Transmission";
          url = me "transmission";
          icon = "transmission.svg";
        }
      ];
    }
    {
      name = "Productivity";
      items = [
        {
          label = "Apparatus";
          url = "https://bfd.firecat53.com";
          icon = "apparatus.svg";
        }
        {
          label = "Forgejo";
          url = me "git";
          icon = "forgejo.svg";
        }
        {
          label = "LubeLogger";
          url = me "cars";
          icon = "lubelogger.png";
        }
        {
          label = "Microbin";
          url = me "mb";
          icon = "microbin.svg";
        }
        {
          label = "Miniflux";
          url = me "rss";
          icon = "miniflux.svg";
        }
        {
          label = "Nextcloud";
          badge = "home";
          url = "https://nc.firecat53.net";
          icon = "nextcloud.svg";
        }
        {
          label = "Nextcloud";
          badge = "vps";
          url = "https://nc.firecat53.com";
          icon = "nextcloud.svg";
        }
        {
          label = "SearXNG";
          url = me "search";
          icon = "searxng.svg";
        }
        {
          label = "Stirling PDF";
          url = me "pdf";
          icon = "stirling-pdf.svg";
        }
        {
          label = "Today";
          url = me "today";
          icon = "today.svg";
        }
        {
          label = "Vaultwarden";
          url = me "bw";
          icon = "vaultwarden.svg";
        }
        {
          label = "Wiki";
          url = me "gollum";
          icon = "gollum.svg";
        }
      ];
    }
    {
      name = "Communications";
      items = [
        {
          label = "Akkoma";
          url = "https://s.firecat53.net";
          icon = "akkoma.svg";
        }
        {
          label = "Matrix";
          url = "https://matrix.to/#/@firecat53:firecat53.net";
          icon = "matrix.svg";
        }
      ];
    }
    {
      name = "Infrastructure";
      items = [
        {
          label = "Alertmanager";
          url = me "alerts";
          icon = "alertmanager.svg";
        }
        {
          label = "Authelia";
          url = "https://auth.firecat53.me";
          icon = "authelia.svg";
        }
        {
          label = "Grafana";
          url = "https://grafana.firecat53.com";
          icon = "grafana.svg";
        }
        {
          label = "Home Assistant";
          url = me "hass";
          icon = "home-assistant.svg";
        }
        {
          label = "Monitoring";
          badge = "home";
          url = me "uph";
          icon = "gatus.svg";
        }
        {
          label = "Monitoring";
          badge = "vps";
          url = me "up";
          icon = "gatus.svg";
        }
        {
          label = "Prometheus";
          url = me "prom";
          icon = "prometheus.svg";
        }
        {
          label = "Syncthing";
          badge = "home";
          url = me "syncthing";
          icon = "syncthing.svg";
        }
        {
          label = "Syncthing";
          badge = "local";
          url = "http://localhost:8384";
          icon = "syncthing.svg";
        }
        {
          label = "Syncthing";
          badge = "vps";
          url = "https://syncthing.firecat53.com";
          icon = "syncthing.svg";
        }
        {
          label = "Traefik";
          badge = "home";
          url = "https://monitor.lan.firecat53.net";
          icon = "traefik.svg";
        }
        {
          label = "Traefik";
          badge = "vps";
          url = "https://monitor.firecat53.com";
          icon = "traefik.svg";
        }
      ];
    }
  ];

  site = localPkgs.dashboard {
    title = "Home";
    inherit groups;
  };
in
{
  # Served by the existing nginx (defaultHTTPListenPort = 8080), matched on the
  # Host header so it coexists with the lan.firecat53.net vhost.
  services.nginx.virtualHosts."home.lan.firecat53.net" = {
    root = "${site}";
    locations."/".index = "index.html";
  };

  # Router/service named `home-dash` to avoid colliding with the Traefik API
  # `dashboard` router defined in traefik.nix.
  services.traefik.dynamicConfigOptions.http.routers.home-dash = {
    rule = "Host(`home.lan.firecat53.net`)";
    service = "home-dash";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls.certResolver = "le";
  };
  services.traefik.dynamicConfigOptions.http.services.home-dash.loadBalancer.servers = [
    { url = "http://localhost:8080"; }
  ];
}
