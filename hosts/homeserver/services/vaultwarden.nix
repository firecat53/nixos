# Vaultwarden
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.vaultwarden-env = { };

  # Create backup directory
  systemd.tmpfiles.rules = [
    "d /var/backups/vaultwarden 0700 vaultwarden vaultwarden -"
  ];

  services.vaultwarden = {
    enable = true;
    package = pkgs.vaultwarden;
    dbBackend = "sqlite";
    config = {
      DOMAIN = "https://bw.lan.firecat53.net";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = "8082";
    };
    environmentFile = "${config.sops.secrets.vaultwarden-env.path}";
    backupDir = "/var/backups/vaultwarden";
  };

  # Traefik routers/service generated from the registry (bw entry) by lan-proxy.nix.
}
