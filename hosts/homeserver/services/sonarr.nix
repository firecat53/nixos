# Sonarr
{
  services.sonarr = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/sonarr";
  };
  # Root folders are on datapool. Ordering on the mount means a rebuild that
  # cycles the pool restarts sonarr instead of letting it run on across an empty
  # tree and mark the whole library missing.
  systemd.services.sonarr.unitConfig.RequiresMountsFor = "/mnt/downloads";
  # Traefik routers/service generated from the registry (sonarr entry) by lan-proxy.nix.
}
