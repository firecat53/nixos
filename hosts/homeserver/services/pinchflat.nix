# Pinchflat
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.pinchflat-env = { };
  services.pinchflat = {
    package = pkgs.pinchflat;
    enable = true;
    group = "users";
    mediaDir = "/mnt/media/youtube";
    secretsFile = "${config.sops.secrets.pinchflat-env.path}";
    user = "firecat53";
  };
  # Traefik routers/service generated from the registry (yt entry, lanOnly) by lan-proxy.nix.
}
