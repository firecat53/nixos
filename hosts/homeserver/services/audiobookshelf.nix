# Audiobookshelf
{
  pkgs,
  ...
}:
{
  services.audiobookshelf = {
    package = pkgs.audiobookshelf;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "audiobookshelf";
  };
  # Traefik routers/service generated from the registry (books entry) by lan-proxy.nix.
}
