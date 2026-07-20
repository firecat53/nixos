# Sabnzbd
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.sabnzbd = {
    package = pkgs.sabnzbd;
    enable = true;
    configFile = null;
    allowConfigWrite = true;
    user = "firecat53";
    group = "users";
  };
  # Override sabnzbd default
  systemd.tmpfiles.rules = [
    "d /var/lib/sabnzbd 0700 firecat53 users - "
  ];
  # The user/group option handling is broken and the default 8080 port conflicts with other services.
  # I also changed the service type to simple instead of forking so the logs show up in the journal.
  systemd.services.sabnzbd.serviceConfig = {
    Type = lib.mkForce "simple";
    ExecStart = lib.mkForce "${config.services.sabnzbd.package}/bin/sabnzbd -f /var/lib/sabnzbd/sabnzbd.ini -s 127.0.0.1:8090";
  };
  # Traefik routers/service generated from the registry (sabnzbd entry) by lan-proxy.nix.
}
