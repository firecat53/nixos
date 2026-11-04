# Traefik
{
  config,
  ...
}:
{
  imports = [
    ../../modules/traefik-base.nix
    ../../modules/crowdsec.nix
  ];

  traefikBase = {
    dashboardHost = "monitor.lan.firecat53.net";
    acmeDnsProvider = "porkbun";
    acmeResolvers = [ "1.1.1.1:53" ];
  };

  # Porkbun API token for DNS-01 certs (firecat53.net and *.lan.firecat53.net)
  sops.secrets.porkbun-api-keys = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.porkbun-api-keys.path;
}
