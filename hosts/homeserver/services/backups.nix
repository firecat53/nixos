{
  config,
  sops,
  ...
}:{
  # Backup user for pull backups from backup server
  users.users.backup = {
    isNormalUser = true;
    uid = 20001;
    group = "root";
    home = "/var/lib/backup";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup"
    ];
  };
  # Postgres backup
  services.postgresqlBackup = {
    enable = true;
    location = "/var/backups";
    backupAll = true;
  };
  # Mysql/maridb backup
  services.mysqlBackup = {
    enable = true;
    location = "/var/backups";
    databases = [
      "nextcloud"
    ];
    singleTransaction = true;
    user = "root";
  };
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
    datasets."backup" = {
      # Prune local backups
      useTemplate = ["backup"];
      process_children_only = true;
      recursive = true;
    };
    datasets."backup1" = {
      # Prune local backups
      useTemplate = ["backup"];
      process_children_only = true;
      recursive = true;
    };
    datasets."downloadpool" = {
      useTemplate = ["downloads"];
      process_children_only = true;
      recursive = true;
    };
    templates."data" = {
      hourly = 48;
      daily = 30;
      monthly = 6;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
    templates."backup" = {
      hourly = 48;
      daily = 30;
      monthly = 6;
      yearly = 0;
      autosnap = false;
      autoprune = true;
    };
    templates."downloads" = {
      hourly = 0;
      daily = 2;
      monthly = 0;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
  };

  ### Syncoid
  ## `backup` pool (for all data except `downloads`)
  ## `backup1` pool is external SSD (for all data except `downloads`)
  services.syncoid = {
    enable = true;
    commonArgs = [
      "--no-privilege-elevation"
      "--no-sync-snap"
    ];
    service = {
      after = ["sanoid.service"];
      wants = ["sanoid.service"];
      serviceConfig = {
        Type = "oneshot";
      };
    };
    commands.backup-data = {
      source = "rpool/data";
      target = "backup";
      service = {
        after = ["syncoid-backup1-data.service"];
        wants = ["syncoid-backup1-data.service"];
      };
      recursive = true;
      extraArgs = [
        "--skip-parent"
      ];
    };
    commands.backup1-data = {
      source = "rpool/data";
      target = "backup1";
      service = {
        before = ["syncoid-backup-data.service"];
      };
      recursive = true;
      extraArgs = [
        "--skip-parent"
      ];
    };
  };

  ### Restic
  sops.secrets.restic_env = {};
  sops.secrets.restic_repo = {};
  sops.secrets.restic_password = {};

  services.restic = {
    backups.homeserver = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile =  "${config.sops.secrets.restic_repo.path}";
      passwordFile =  "${config.sops.secrets.restic_password.path}";
      paths = [
        "/home"
        "/mnt/media"
        "/srv"
        "/var/backups"
        "/var/lib"
      ];
      exclude = [
        "/var/lib/containers/*"
        "!/var/lib/containers/storage"
        "/var/lib/containers/storage/*"
        "!/var/lib/containers/storage/volumes"
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
      ];
      extraBackupArgs = [
        "--retry-lock 30m"
      ];
    };
  };

}
