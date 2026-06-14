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
  ...
}:
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
          # KEEP IN SYNC with the `auth = true` entries in proxy-me.nix.
          {
            domain = [
              "gollum.firecat53.me"
              "jackett.firecat53.me"
              "cars.firecat53.me"
              "rss.firecat53.me"
              "radarr.firecat53.me"
              "sonarr.firecat53.me"
              "sabnzbd.firecat53.me"
              "qbt.firecat53.me"
              "transmission.firecat53.me"
              "pdf.firecat53.me"
              "today.firecat53.me"
              "uph.firecat53.me"
              "syncthing.firecat53.me"
              "search.firecat53.me"
            ];
            policy = "two_factor";
          }
        ];
      };
    };
  };
}
