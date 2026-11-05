# Public front door for the firecat53.net apps (Matrix, Akkoma) and the
# firecat53.net / firecat53.com static site.
#
# TLS terminates here; requests go over wireguard to the homeserver's Traefik
# with the real Host header, so its routers (akkoma.nix, matrix-continuwuity.nix,
# nginx.nix) match unchanged.
let
  inherit (import ../../modules/service-registry.nix) hsIP;
  hosts = [
    "firecat53.net"
    "matrix.firecat53.net"
    "s.firecat53.net"
    "sm.firecat53.net"
  ];
in
{
  services.traefik.dynamicConfigOptions.http = {
    # The homeserver's sniStrict rejects SNI-less handshakes to its IP. One
    # fixed SNI is enough; its routers then match on the passed Host header.
    serversTransports.wg-homeserver-net = {
      serverName = "firecat53.net";
      insecureSkipVerify = true;
    };
    routers.firecat53-net = {
      rule = builtins.concatStringsSep " || " (map (h: "Host(`${h}`)") hosts);
      service = "firecat53-net";
      entrypoints = [ "websecure" ];
      tls.certResolver = "le";
    };
    # Covered by the firecat53.com wildcard cert (traefik.nix)
    routers.firecat53-com = {
      rule = "Host(`firecat53.com`)";
      service = "firecat53-net";
      entrypoints = [ "websecure" ];
    };
    services.firecat53-net.loadBalancer = {
      passHostHeader = true;
      serversTransport = "wg-homeserver-net";
      servers = [ { url = "https://${hsIP}"; } ];
    };
  };
}
