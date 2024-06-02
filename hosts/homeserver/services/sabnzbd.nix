# Sabnzbd
{
  config,
  lib,
  pkgs,
  ...
}:{
  services.sabnzbd = {
    package = pkgs.sabnzbd;
    enable = true;
  };
  # Override sabnzbd default
  systemd.tmpfiles.rules = [
    "d /var/lib/sabnzbd 0700 firecat53 users - "
  ];
  # The user/group option handling is broken and the default 8080 port conflicts with other services.
  # I also changed the service type to simple instead of forking so the logs show up in the journal.
  systemd.services.sabnzbd.serviceConfig = {
    Type = lib.mkForce "simple";
    User = lib.mkForce "firecat53";
    Group = lib.mkForce "users";
    ExecStart = lib.mkForce "${config.services.sabnzbd.package}/bin/sabnzbd -f ${config.services.sabnzbd.configFile} -s 127.0.0.1:8090";
  };
  services.traefik.dynamicConfigOptions.http.routers.sabnzbd = {
    rule = "Host(`sabnzbd.lan.firecat53.net`)";
    service = "sabnzbd";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.sabnzbd = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8090";
        }
      ];
    };
  };
}
