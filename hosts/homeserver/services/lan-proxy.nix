# Traefik routers/services for the standard *.lan.firecat53.net web services,
# generated from the shared service registry (single source of truth — see
# ../../modules/service-registry.nix for the entry format and flag docs).
#
# Every entry gets a router on its `lan` host + a loadBalancer service; the
# explicit per-entry flags (basicAuth, meRouter, vpsBypass) each add exactly
# one more thing. Nothing here is conditional on anything else — to see the
# final rendered config:
#
#   nix eval --json .#nixosConfigurations.homeserver.config.services.traefik.dynamicConfigOptions | jq
#
# Oddballs (path rules, extra middlewares, non-.lan hosts) stay hand-written in
# their own service files: matrix-synapse, akkoma, nextcloud, nginx (lan apex).
{
  lib,
  ...
}:
let
  inherit (import ../../modules/service-registry.nix) homeserver lanOnly vpsIP;

  # All homeserver-hosted services with a standard .lan router, keyed by their
  # public subdomain (also used as the router/service name).
  registry = homeserver // lanOnly;

  backend = s: s.url or "http://localhost:${toString s.port}";

  mkRouters =
    name: s:
    {
      # <name>.lan.firecat53.net for LAN/wireguard clients.
      ${name} = {
        rule = "Host(`${s.lan}`)";
        service = name;
        middlewares = lib.optional (s.basicAuth or false) "auth" ++ [ "headers" ];
        entrypoints = [ "websecure" ];
        tls.certResolver = "le";
      };
    }
    // lib.optionalAttrs (s.meRouter or false) {
      # Companion router on the real *.firecat53.me host (registry passHost —
      # apps that build absolute URLs/redirects from the Host header). That
      # host only ever arrives via the VPS, already 2FA'd by Authelia, so no
      # basicAuth. No certResolver: the VPS->homeserver TLS uses the .lan SNI,
      # whose cert the router above provisions (firecat53.me certs live on the
      # VPS, which has the Porkbun DNS credentials — not here).
      "${name}-me" = {
        rule = "Host(`${name}.firecat53.me`)";
        service = name;
        middlewares = [ "headers" ];
        entrypoints = [ "websecure" ];
        tls = { };
      };
    }
    // lib.optionalAttrs (s.vpsBypass or false) {
      # basicAuth bypass for requests from the VPS (proxied *.firecat53.me
      # traffic is already 2FA'd; Gatus probes reach the real backend so an
      # outage shows as 502 instead of the auth middleware's 401). Relies on
      # this Traefik not trusting forwarded headers, so ClientIP is the real
      # TCP source. LAN/wireguard clients hit the plain router above.
      "${name}-noauth" = {
        rule = "Host(`${s.lan}`) && ClientIP(`${vpsIP}`)";
        service = name;
        priority = 100; # beat the plain Host() router
        middlewares = [ "headers" ];
        entrypoints = [ "websecure" ];
        tls.certResolver = "le";
      };
    };
in
{
  services.traefik.dynamicConfigOptions.http = {
    routers = lib.concatMapAttrs mkRouters registry;
    services = lib.mapAttrs (_: s: {
      loadBalancer.servers = [ { url = backend s; } ];
    }) registry;
  };
}
