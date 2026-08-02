# Seerr (formerly Jellyseerr) - media request manager
{
  pkgs,
  ...
}:
{
  services.seerr = {
    enable = true;
    package = pkgs.unstable.seerr;
  };
  # Jellyfin/Radarr/Sonarr connections aren't module options - they live in
  # $configDir/settings.json, written by the app's first-run setup wizard.
  # configDir stays at the pre-26.05 default (/var/lib/jellyseerr/config),
  # gated on stateVersion; it must match the unit's StateDirectory.

  # Traefik routers/service generated from the registry (seerr entry) by lan-proxy.nix.
}
