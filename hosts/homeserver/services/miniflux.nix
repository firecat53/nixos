# Miniflux
{
  config,
  ...
}:
{
  sops.secrets.miniflux-env = { };
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "localhost:8085";
      FETCHER_ALLOW_PRIVATE_NETWORKS = "true";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://rss.firecat53.me/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.firecat53.me";
      OAUTH2_OIDC_PROVIDER_NAME = "Authelia";
      OAUTH2_USER_CREATION = 1;
    };
    adminCredentialsFile = "${config.sops.secrets.miniflux-env.path}";
  };

  services.traefik.dynamicConfigOptions.http.routers.miniflux = {
    rule = "Host(`rss.lan.firecat53.net`)";
    service = "miniflux";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  # Router for the public *.firecat53.me host (proxied from the VPS with
  # passHostHeader=true) so the OAuth Origin/redirect matches.
  services.traefik.dynamicConfigOptions.http.routers.miniflux-me = {
    rule = "Host(`rss.firecat53.me`)";
    service = "miniflux";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = { };
  };
  services.traefik.dynamicConfigOptions.http.services.miniflux = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8085";
        }
      ];
    };
  };
}
