# Backups - sanoid and restic.
{
  config,
  ...
}:
{
  ### Sanoid
  services.sanoid = {
    enable = true;
    datasets."rpool/nixos/var/lib" = {
      useTemplate = [ "data" ];
      process_children_only = false;
      recursive = false;
    };
    templates."data" = {
      hourly = 48;
      daily = 30;
      monthly = 6;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
  };

  ### Restic
  sops.secrets.restic_env = { };
  sops.secrets.restic_repo = { };
  sops.secrets.restic_password = { };

  services.restic = {
    backups.pangolin = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile = "${config.sops.secrets.restic_repo.path}";
      passwordFile = "${config.sops.secrets.restic_password.path}";
      paths = [
        "/var/lib"
      ];
      timerConfig = {
        OnBootSec = "15m";
        OnCalendar = "daily";
        RandomizedDelaySec = "3h";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-monthly 6"
        "--keep-weekly 12"
        "--keep-daily 30"
      ];
      extraBackupArgs = [
        "--retry-lock 30m"
      ];
    };
  };
}
