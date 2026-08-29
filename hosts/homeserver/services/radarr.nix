# Radarr
{
  pkgs,
  ...
}:
{
  services.radarr = {
    package = pkgs.radarr;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/radarr";
  };
  # Same as sonarr: root folder is on datapool, so order on the mount rather
  # than let a pool cycle look like the whole library was deleted.
  systemd.services.radarr.unitConfig.RequiresMountsFor = "/mnt/downloads";
  # Traefik routers/service generated from the registry (radarr entry) by lan-proxy.nix.
}
