### Lubelogger
{
  config,
  ...
}:
{
  sops.secrets.lubelogger-oidc-secret = { };

  services.lubelogger = {
    enable = true;
    # The user's OIDC email must match a registered LubeLogger user.
    settings = {
      OpenIDConfig__Name = "Authelia";
      OpenIDConfig__ClientId = "lubelogger";
      OpenIDConfig__AuthURL = "https://auth.firecat53.me/api/oidc/authorization";
      OpenIDConfig__TokenURL = "https://auth.firecat53.me/api/oidc/token";
      OpenIDConfig__UserInfoURL = "https://auth.firecat53.me/api/oidc/userinfo";
      OpenIDConfig__RedirectURL = "https://cars.firecat53.me/Login/RemoteAuth";
      OpenIDConfig__Scope = "openid profile email";
    };
    environmentFile = config.sops.secrets.lubelogger-oidc-secret.path;
  };

  services.traefik.dynamicConfigOptions.http.routers.lubelogger = {
    rule = "Host(`cars.lan.firecat53.net`)";
    service = "lubelogger";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  # Router for the public *.firecat53.me host (proxied from the VPS with
  # passHostHeader=true) so the OAuth Origin/redirect matches.
  services.traefik.dynamicConfigOptions.http.routers.lubelogger-me = {
    rule = "Host(`cars.firecat53.me`)";
    service = "lubelogger";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = { };
  };
  services.traefik.dynamicConfigOptions.http.services.lubelogger = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:5000";
        }
      ];
    };
  };
}
