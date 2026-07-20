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

  # Traefik routers/service generated from the registry (cars entry) by lan-proxy.nix.
}
