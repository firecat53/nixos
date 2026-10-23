# ntfy - UnifiedPush distributor, Matrix push gateway and Gatus alert target
{
  config,
  ...
}:
let
  fqdn = "ntfy.firecat53.com";
in
{
  sops.secrets.ntfy-admin-hash = { };
  sops.secrets.ntfy-gatus-token = { };
  # Declarative admin user + Gatus publish token (ntfy auth-users/auth-tokens).
  sops.templates."ntfy.env" = {
    content = ''
      NTFY_AUTH_USERS=firecat53:${config.sops.placeholder.ntfy-admin-hash}:admin
      NTFY_AUTH_TOKENS=firecat53:${config.sops.placeholder.ntfy-gatus-token}:gatus
    '';
    restartUnits = [ "ntfy-sh.service" ];
  };

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.templates."ntfy.env".path;
    settings = {
      base-url = "https://${fqdn}";
      behind-proxy = true;
      auth-default-access = "deny-all";
      # UnifiedPush app servers (incl. Synapse's Matrix gateway) publish
      # anonymously; the phone subscribes as firecat53.
      auth-access = [ "*:up*:write-only" ];
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.ntfy = {
    rule = "Host(`${fqdn}`)";
    service = "ntfy";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.ntfy = {
    loadBalancer = {
      servers = [
        {
          url = "http://${config.services.ntfy-sh.settings.listen-http}";
        }
      ];
    };
  };
}
