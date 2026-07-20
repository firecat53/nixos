# Sonarr
{
  services.sonarr = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/sonarr";
  };
  # Traefik routers/service generated from the registry (sonarr entry) by lan-proxy.nix.
}
