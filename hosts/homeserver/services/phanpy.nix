# Phanpy - alternate web client for Akkoma (s.firecat53.net). Static site
# served by nginx at:
#   - phanpy.lan.firecat53.net and phanpy.firecat53.me (Authelia 2FA)
{
  pkgs,
  ...
}:
let
  localPkgs = import ../../../pkgs { inherit pkgs; };
in
{
  # Same nginx/Host-header setup as the dashboard. Traefik routers/service
  # generated from the registry (phanpy entry) by lan-proxy.nix.
  services.nginx.virtualHosts."phanpy.lan.firecat53.net" = {
    root = "${localPkgs.phanpy}";
    locations."/".index = "index.html";
  };
}
