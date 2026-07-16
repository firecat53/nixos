# Traefik
{
  config,
  ...
}:
{
  imports = [ ../../modules/traefik-base.nix ];

  traefikBase = {
    dashboardHost = "monitor.lan.firecat53.net";
    acmeDnsProvider = "cloudflare";
    acmeResolvers = [ "1.1.1.1:53" ];
  };

  sops.secrets.cf-api-token = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  systemd.services.traefik.environment = {
    CF_DNS_API_TOKEN_FILE = "${config.sops.secrets.cf-api-token.path}";
  };
}
