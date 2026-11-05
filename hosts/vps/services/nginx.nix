# Nginx (only Nextcloud uses it; the firecat53.com site is served by the
# homeserver via proxy-net.nix)
{
  services.nginx.defaultHTTPListenPort = 8080; # Keep off Traefik's :80
}
