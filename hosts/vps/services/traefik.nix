# Traefik
{
  config,
  ...
}:
{
  imports = [ ../../modules/traefik-base.nix ];

  traefikBase = {
    dashboardHost = "monitor.firecat53.com";
    acmeDnsProvider = "porkbun";
  };

  networking.firewall.allowedTCPPorts = [ 2222 ]; # Forgejo SSH

  # Porkbun API token for DNS-01 wildcard certs (*.firecat53.com / *.firecat53.me)
  sops.secrets.porkbun-api-keys = {
    mode = "0440";
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
  };
  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.porkbun-api-keys.path;

  services.traefik.staticConfigOptions.entryPoints = {
    # Merges with the base websecure entrypoint definition
    websecure.http.tls = {
      certResolver = "le";
      # Default wildcard certs for all routers on this entrypoint.
      domains = [
        {
          main = "firecat53.com";
          sans = [ "*.firecat53.com" ];
        }
        {
          main = "firecat53.me";
          sans = [ "*.firecat53.me" ];
        }
      ];
    };
    "tcp-2222" = {
      address = ":2222/tcp";
    };
  };
}
