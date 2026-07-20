# Jackett
{
  pkgs,
  ...
}:
{
  services.jackett = {
    package = pkgs.jackett;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/jackett";
  };
  # Disable failing tests (2025-01-15)
  nixpkgs.overlays = [
    (final: prev: {
      jackett = prev.jackett.overrideAttrs { doCheck = false; };
    })
  ];
  # Traefik routers/service generated from the registry (jackett entry) by lan-proxy.nix.
}
