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
        networks = [
          {
            name = "mesh";
            networks = [
              "10.200.200.0/24" # wireguard mesh
              "192.168.200.0/24" # home LAN
            ];
          }
        ];
        rules = [
          # On the mesh/LAN: never prompt for auth
          {
            domain = [
              "*.firecat53.me"
              "*.firecat53.com"
            ];
            policy = "bypass";
            networks = [ "mesh" ];
          }
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
