{
  # Services on homeserver that need monitoring
  networking.extraHosts = ''
    10.200.200.6 bw.lan.firecat53.net
    10.200.200.6 gollum.lan.firecat53.net
    10.200.200.6 hass.lan.firecat53.net
    10.200.200.6 jellyfin.lan.firecat53.net
    10.200.200.6 monitor.lan.firecat53.net
    10.200.200.6 nc.firecat53.net
    10.200.200.6 qbt.lan.firecat53.net
    10.200.200.6 radarr.lan.firecat53.net
    10.200.200.6 rss.lan.firecat53.net
    10.200.200.6 sabnzbd.lan.firecat53.net
    10.200.200.6 sonarr.lan.firecat53.net
    10.200.200.6 syncthing.lan.firecat53.net
    10.200.200.6 transmission.lan.firecat53.net
  '';
  services.uptime-kuma = {
    enable = true;
  };
  services.traefik.dynamicConfigOptions.http.routers.up = {
    rule = "Host(`up.firecat53.com`)";
    service = "up";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.up = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3001";
        }
      ];
    };
  };
}
