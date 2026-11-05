# Continuwuity Matrix homeserver (public via the VPS, see vps/services/proxy-net.nix)
{
  config,
  pkgs,
  ...
}:
let
  domain = "firecat53.net";
  fqdn = "matrix.${domain}";
  port = 6167; # module default
  router = rule: {
    inherit rule;
    service = "matrix";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls.certResolver = "le";
  };
in
{
  sops.secrets.continuwuity-registration-token = { };

  services.matrix-continuwuity = {
    enable = true;
    # The default 0.5.x is marked insecure (SEC8); 26.x carries the fix
    package = pkgs.matrix-continuwuity_latest;
    settings.global = {
      server_name = domain;
      # Served by continuwuity itself on both hosts (routers below)
      well_known = {
        client = "https://${fqdn}";
        server = "${fqdn}:443";
      };
      url_preview_domain_explicit_allowlist = [ "*" ];
      new_user_displayname_suffix = "🐇";
      # First-account bootstrap only; remove once @scott exists
      allow_registration = true;
      registration_token_file = "/run/credentials/continuwuity.service/registration-token";
    };
  };
  # DynamicUser can't read sops files directly
  systemd.services.continuwuity.serviceConfig.LoadCredential = [
    "registration-token:${config.sops.secrets.continuwuity-registration-token.path}"
  ];

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      matrix = router "Host(`${fqdn}`)";
      matrix-wellknown-root = router "Host(`${domain}`) && PathPrefix(`/.well-known/matrix/`)";
    };
    services.matrix.loadBalancer.servers = [ { url = "http://localhost:${toString port}"; } ];
  };
}
