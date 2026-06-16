# Public reverse-proxy routers for *.firecat53.me.
#
# Homeserver-hosted services are reached over the wireguard mesh by proxying
# to the homeserver's *existing* Traefik (10.200.200.6) using its .lan name as
# the backend with passHostHeader=false, so its current routers match unchanged
# and serve the correct cert. The .lan names resolve to the homeserver via the
# networking.hosts entries below. TLS for *.firecat53.me terminates here.
{
  lib,
  ...
}:
let
  # Service registry is the single source of truth (see registry.nix). Authelia
  # and uptime-kuma derive their views from the same file.
  inherit (import ./registry.nix) hsIP remote local;

  mw = auth: [ "headers" ] ++ lib.optional auth "authelia";

  # Prefix generated router/service names with "me-" to avoid clashing with the
  # existing *.firecat53.com routers (e.g. syncthing) on this host.
  renamed = fn: set: lib.mapAttrs' (name: s: lib.nameValuePair "me-${name}" (fn name s)) set;

  mkRemoteRouter = name: s: {
    rule = "Host(`${name}.firecat53.me`)";
    service = "me-${name}";
    entrypoints = [ "websecure" ];
    middlewares = mw s.auth;
  };
  mkRemoteService = _: s: {
    loadBalancer = {
      # Default false: send the .lan name as Host so the homeserver's existing
      # routers match. Opt into passHost = true for apps that build absolute
      # URLs/redirects from the Host header (e.g. gollum) — they need the real
      # *.firecat53.me host plus a matching homeserver router. See registry.nix.
      passHostHeader = s.passHost or false;
      servers = [ { url = "https://${s.lan}"; } ];
    };
  };
  mkLocalRouter = name: s: {
    rule = "Host(`${name}.firecat53.me`)";
    service = "me-${name}";
    entrypoints = [ "websecure" ];
    middlewares = mw s.auth;
  };
  mkLocalService = _: s: {
    loadBalancer.servers = [ { url = "http://localhost:${toString s.port}"; } ];
  };
in
{
  # Resolve homeserver .lan names across the wireguard tunnel.
  networking.hosts."${hsIP}" = map (s: s.lan) (lib.attrValues remote);

  # Forgejo SSH: TCP passthrough to the homeserver's built-in SSH server
  # (forgejo SSH_LISTEN_PORT = 3022). Must be reachable on the wg interface.
  services.traefik.dynamicConfigOptions.tcp = {
    routers.forgejo-ssh = {
      rule = "HostSNI(`*`)";
      entrypoints = [ "tcp-2222" ];
      service = "forgejo-ssh";
    };
    services.forgejo-ssh.loadBalancer.servers = [ { address = "${hsIP}:3022"; } ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers =
      (renamed mkRemoteRouter remote)
      // (renamed mkLocalRouter local)
      // {
        # Authelia login portal (no forward-auth on itself)
        auth = {
          rule = "Host(`auth.firecat53.me`)";
          service = "authelia";
          entrypoints = [ "websecure" ];
        };
        auth-com = {
          rule = "Host(`auth.firecat53.com`)";
          service = "authelia";
          entrypoints = [ "websecure" ];
        };
      };
    services =
      (renamed mkRemoteService remote)
      // (renamed mkLocalService local)
      // {
        authelia.loadBalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
      };
    middlewares = {
      authelia.forwardAuth = {
        address = "http://127.0.0.1:9091/api/authz/forward-auth";
        trustForwardHeader = true;
        authResponseHeaders = [
          "Remote-User"
          "Remote-Groups"
          "Remote-Name"
          "Remote-Email"
        ];
      };
    };
  };
}
