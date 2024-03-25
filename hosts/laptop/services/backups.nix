{
  config,
  sops,
  ...
}:{
  # Sanoid
  services.sanoid = {
    enable = true;
    datasets."rpool/data" = {
      useTemplate = ["data"];
      process_children_only = true;
      recursive = true;
    };
    datasets."rpool/nixos/var/lib" = {
      useTemplate = ["data"];
      process_children_only = false;
      recursive = false;
    };
    datasets."rpool/nixos/var/lib/containers/storage/volumes" = {
      useTemplate = ["data"];
      process_children_only = false;
      recursive = false;
    };
    templates."data" = {
      hourly = 72;
      daily = 30;
      monthly = 0;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
  };

  ### Restic
  sops.secrets.restic_env = {};
  sops.secrets.restic_repo = {};
  sops.secrets.restic_password = {};

  services.restic = {
    backups.laptop = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile =  "${config.sops.secrets.restic_repo.path}";
      passwordFile =  "${config.sops.secrets.restic_password.path}";
      paths = [
        "/home"
      ];
      exclude = [
        "/home/firecat53/.cache"
        "/home/firecat53/.local/pipx/"
        "/home/firecat53/.local/state/"
        "/home/firecat53/.local/tmp/iso"
      ];
      timerConfig = {
        OnBootSec = "15m";
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-monthly 6"
        "--keep-weekly 12"
        "--keep-daily 30"
        "--keep-hourly 72"
      ];
      extraBackupArgs = [
        "--retry-lock 30m"
      ];
    };
  };
  # Allow restic-backup to restart if failed
  systemd.services.restic-backups-laptop = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "20";
    };
    unitConfig = {
      StartLimitIntervalSec = 100;
      StartLimitBurst = 5;
    };
  };
}
