# Authelia - forward-auth SSO for protected *.firecat53.me / *.firecat53.com
# resources (replaces Pangolin's resource authentication).
#
# Required secrets (add to vps/secrets.yaml in the nixos-secrets repo):
#   authelia-jwt              - random string (JWT signing)
#   authelia-session          - random string (session cookie signing)
#   authelia-storage          - random string (sqlite encryption key)
#   authelia-users            - users_database.yml (argon2 hashes + TOTP)
#
# Generate users file with:  authelia crypto hash generate argon2 --password '...'
{
  config,
  lib,
  ...
}:
let
  # Protected resources are derived from the service registry (auth = true),
  # so this list can never drift from proxy-me.nix.
  reg = import ./registry.nix;
  protected =
    (lib.filterAttrs (_: s: s.auth) reg.remote) // (lib.filterAttrs (_: s: s.auth) reg.local);
  protectedDomains = map (n: "${n}.firecat53.me") (lib.attrNames protected);
in
{
  sops.secrets = {
    authelia-jwt.owner = "authelia-main";
    authelia-session.owner = "authelia-main";
    authelia-storage.owner = "authelia-main";
    authelia-users.owner = "authelia-main";
  };

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia-jwt.path;
      sessionSecretFile = config.sops.secrets.authelia-session.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia-storage.path;
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

      access_control = {
        default_policy = "deny";
        # Note: there is intentionally no mesh/LAN bypass rule here. Authelia
        # only ever sees *.firecat53.me traffic that egressed to the VPS's
        # public IP, so the client IP is never a mesh address — a bypass keyed
        # on mesh networks would be dormant. LAN/wireguard clients use the
        # *.lan.firecat53.net names (native basicAuth) instead; see README.
        rules = [
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
}
