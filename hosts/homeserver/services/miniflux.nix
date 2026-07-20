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

  # Traefik routers/service generated from the registry (rss entry) by lan-proxy.nix.
}
