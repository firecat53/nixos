# Sabnzbd
{
  config,
  lib,
  ...
}:
{
  services.sabnzbd = {
    enable = true;
    configFile = null; # manage the ini through `settings` instead of the legacy file
    allowConfigWrite = true;
    user = "firecat53";
    group = "users";
    settings.misc.port = 8090;
  };
  systemd.services.sabnzbd.serviceConfig = {
    # Upstream daemonizes with -d; run in the foreground so logs reach the journal.
    Type = lib.mkForce "simple";
    ExecStart = lib.mkForce "${lib.getExe config.services.sabnzbd.package} -f /var/lib/${config.services.sabnzbd.stateDir}/sabnzbd.ini";
    StateDirectoryMode = "0700";
  };
  # Traefik routers/service generated from the registry (sabnzbd entry) by lan-proxy.nix.
}
