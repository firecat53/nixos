# Bazarr - subtitle downloads for Sonarr/Radarr
{
  services.bazarr = {
    enable = true;
    # Writes .srt files next to the media, so it needs the same owner as the *arrs.
    user = "firecat53";
    group = "users";
  };
  # Same as sonarr/radarr: media is on datapool.
  systemd.services.bazarr.unitConfig.RequiresMountsFor = "/mnt/downloads";
  # Traefik routers/service generated from the registry (bazarr entry) by lan-proxy.nix.
}
