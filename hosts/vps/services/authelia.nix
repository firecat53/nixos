# Authelia - SSO for protected *.firecat53.me / *.firecat53.com resources
#
# Required secrets (add to vps/secrets.yaml in the nixos-secrets repo):
#   authelia-jwt              - random string (JWT signing)
#   authelia-session          - random string (session cookie signing)
#   authelia-storage          - random string (sqlite encryption key)
#   authelia-users            - users_database.yml (argon2 hashes + TOTP)
#   authelia-oidc-hmac        - random string (OIDC HMAC secret)
#   authelia-oidc-jwks-key    - RSA private key PEM (OIDC token signing)
#
# Generate users file with:  authelia crypto hash generate argon2
#
# OIDC provider. Generate the secrets with:
#   authelia-oidc-hmac:      authelia crypto rand --length 64 --charset rfc3986
#   authelia-oidc-jwks-key:  authelia crypto pair rsa generate    (use private.pem)
# Per-client secret + hash (plaintext goes into the app, hash goes in client
# config below):
#   nix run nixpkgs#authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986
{
  config,
  lib,
  ...
}:
let
  # Forward-auth protected resources are derived from the service registry
  # (auth = true), so this list can never drift from proxy-me.nix.
  reg = import ./registry.nix;
  protected =
    (lib.filterAttrs (_: s: s.auth) reg.remote) // (lib.filterAttrs (_: s: s.auth) reg.local);
  protectedDomains = map (n: "${n}.firecat53.me") (lib.attrNames protected);
in
{
  # Service modules push their own access_control rules here (evaluated before
  # the derived two_factor rule), so per-service Authelia config can live in the
  # service's own module and be removed along with it.
  options.autheliaBypassRules = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [ ];
    description = "Authelia access_control rules evaluated before the blanket two_factor rule.";
  };

  config = {
    sops.secrets = {
      authelia-jwt.owner = "authelia-main";
      authelia-session.owner = "authelia-main";
      authelia-storage.owner = "authelia-main";
      authelia-users.owner = "authelia-main";
      authelia-oidc-hmac.owner = "authelia-main";
      authelia-oidc-jwks-key.owner = "authelia-main";
    };

    # Redis backing Authelia's session store (see settings.session.redis).
    services.redis.servers.authelia = {
      enable = true;
      port = 0;
      unixSocket = "/run/redis-authelia/redis.sock";
      unixSocketPerm = 660;
    };
    users.users.authelia-main.extraGroups = [ "redis-authelia" ];
    systemd.services.authelia-main = {
      after = [ "redis-authelia.service" ];
      wants = [ "redis-authelia.service" ];
    };

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile = config.sops.secrets.authelia-jwt.path;
        sessionSecretFile = config.sops.secrets.authelia-session.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia-storage.path;
        oidcHmacSecretFile = config.sops.secrets.authelia-oidc-hmac.path;
        oidcIssuerPrivateKeyFile = config.sops.secrets.authelia-oidc-jwks-key.path;
      };
      settings = {
        theme = "dark";
        server.address = "tcp://127.0.0.1:9091";
        # Only authenticate the forward-auth endpoint via the session cookie.
        # The default strategies also include HeaderAuthorization, which makes
        # Authelia consume the `Authorization` header — that breaks downstream
        # services that use their own HTTP Basic auth (gollum, today, transmission,
        # syncthing): the browser's `Authorization: Basic <service-creds>` gets
        # validated against Authelia (and fails) instead of passing through to the
        # homeserver Traefik basicAuth. Dropping HeaderAuthorization lets it pass.
        server.endpoints.authz.forward-auth = {
          implementation = "ForwardAuth";
          authn_strategies = [
            { name = "CookieSession"; }
          ];
        };
        log.level = "info";
        totp.issuer = "firecat53.me";

        authentication_backend.file = {
          path = config.sops.secrets.authelia-users.path;
          password.algorithm = "argon2";
        };

        # The default in-memory store drops every session on restart, forcing re-login.
        session.redis = {
          host = "/run/redis-authelia/redis.sock";
          port = 0;
        };

        session.cookies = [
          {
            domain = "firecat53.me";
            authelia_url = "https://auth.firecat53.me";
            default_redirection_url = "https://firecat53.me";
          }
          {
            domain = "firecat53.com";
            authelia_url = "https://auth.firecat53.com";
            default_redirection_url = "https://firecat53.com";
          }
        ];

        storage.local.path = "/var/lib/authelia-main/db.sqlite3";
        notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";

        # OIDC client configurations
        identity_providers.oidc.clients = [
          # Immich
          {
            client_id = "immich";
            client_name = "immich";
            client_secret = "$pbkdf2-sha512$310000$xhCohOhUKduv1okrZ0FAng$jNLWkEu2Mw/ntWsOJTaMawu7n9Vy.VBUY.IMNcg7uxlx0/RbNw9AiOlDFVM5TAi8PrIAx58myEoNlIkcRAGrmQ"; # digest only
            public = false;
            authorization_policy = "two_factor";
            require_pkce = false;
            pkce_challenge_method = "";
            redirect_uris = [
              "https://pics.firecat53.me/auth/login"
              "https://pics.firecat53.me/user-settings"
              "https://pics.firecat53.me/api/oauth/mobile-redirect"
              "app.immich:///oauth-callback"
              # To allow auth from *.lan.firecat53.net
              "https://pics.lan.firecat53.net/auth/login"
              "https://pics.lan.firecat53.net/user-settings"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          }
          # audiobookshelf
          {
            client_id = "audiobookshelf";
            client_name = "audiobookshelf";
            client_secret = "$pbkdf2-sha512$310000$nQGmwUlTUkoYdgTKUGgvtA$XBz433wudd0m3CBizBZ57Oc6laTWLGCZsEYjXxCywvsi8vmpOXk6y/IqjD7CKEWgEjgM.CkxmuRH4o7vX/Kiow"; # digest only
            public = false;
            authorization_policy = "two_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://books.firecat53.me/audiobookshelf/auth/openid/callback"
              "https://books.firecat53.me/audiobookshelf/auth/openid/mobile-redirect"
              "audiobookshelf://oauth"
              # To allow auth from *.lan.firecat53.net
              "https://books.lan.firecat53.net/audiobookshelf/auth/openid/callback"
              "https://books.lan.firecat53.net/audiobookshelf/auth/openid/mobile-redirect"
            ];
            scopes = [
              "openid"
              "profile"
              "groups"
              "email"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];

        access_control = {
          default_policy = "deny";
          # Per-service bypass/override rules (e.g. microbin's public paste
          # viewing) are contributed by the owning service module via
          # `autheliaBypassRules` and evaluated first, so they live and die with
          # that service. Rules are evaluated top-down, first match wins.
          rules = config.autheliaBypassRules ++ [
            # Protected resources: require 2FA from the internet.
            # Derived from registry.nix `auth = true` entries.
            {
              domain = protectedDomains;
              policy = "two_factor";
            }
          ];
        };
      };
    };
  };
}
