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
  # Traefik routers/service generated from the registry (radarr entry) by lan-proxy.nix.
}
