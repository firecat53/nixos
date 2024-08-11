### Lubelogger
{
  pkgs,
  ...
}:{
  virtualisation.oci-containers.containers.lubelogger = {
    image = "ghcr.io/hargata/lubelogger:latest";
    autoStart = true;
    user = "1000:100";
    environment = {
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
      LOGGING__LOGLEVEL__DEFAULT = "Error";
    };
    extraOptions = [
      "--init=true"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.lubelogger.rule=Host(`cars.lan.firecat53.net`)"
      "--label=traefik.http.routers.lubelogger.entrypoints=websecure"
      "--label=traefik.http.routers.lubelogger.tls.certResolver=le"
      "--label=traefik.http.routers.lubelogger.middlewares=headers@file"
      "--label=traefik.http.services.lubelogger.loadbalancer.server.port=8080"
    ];
    volumes = [
      "/var/lib/lubelogger/config:/App/config"
      "/var/lib/lubelogger/data:/App/data"
      "/var/lib/lubelogger/translations:/App/wwwroot/translations"
      "/var/lib/lubelogger/documents:/App/wwwroot/documents"
      "/var/lib/lubelogger/images:/App/wwwroot/images"
      "/var/lib/lubelogger/temp:/App/wwwroot/temp"
      "/var/lib/lubelogger/log:/App/log"
      "/var/lib/lubelogger/keys:/root/.aspnet/DataProtection-Keys"
    ];
  };

  # Create lubelogger config directory
  systemd.tmpfiles.rules = [
    "d /var/lib/lubelogger/config 0700 firecat53 users - "
    "d /var/lib/lubelogger/data 0700 firecat53 users - "
    "d /var/lib/lubelogger/translations 0700 firecat53 users - "
    "d /var/lib/lubelogger/documents 0700 firecat53 users - "
    "d /var/lib/lubelogger/images 0700 firecat53 users - "
    "d /var/lib/lubelogger/temp 0700 firecat53 users - "
    "d /var/lib/lubelogger/log 0700 firecat53 users - "
    "d /var/lib/lubelogger/keys 0700 firecat53 users - "
  ];
}
