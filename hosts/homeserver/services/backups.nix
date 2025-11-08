# Backups - sanoid, syncoid and restic. Database backups are configured in
# postgresql.nix (or mysql.nix if needed)
{
  config,
  ...
}:
{
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
  # Sanoid
  services.sanoid = {
    enable = true;
    datasets."rpool/data" = {
      useTemplate = [ "data" ];
      process_children_only = true;
      recursive = true;
    };
    datasets."rpool/nixos/var/lib" = {
      useTemplate = [ "data" ];
      process_children_only = false;
      recursive = false;
    };
    datasets."backup" = {
      # Prune local backups
      useTemplate = [ "backup" ];
      process_children_only = true;
      recursive = true;
    };
    datasets."downloadpool" = {
      useTemplate = [ "downloads" ];
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
  services.syncoid = {
    enable = false; # TODO re-enable once backup pool gets bigger drive(s)
    commonArgs = [
      "--no-privilege-elevation"
      "--no-sync-snap"
    ];
    service = {
      after = [ "sanoid.service" ];
      wants = [ "sanoid.service" ];
      serviceConfig = {
        Type = "oneshot";
      };
    };
    commands.backup-data = {
      source = "rpool/data";
      target = "backup";
      service = {
        before = [ "syncoid-backup-var-lib.service" ];
      };
      recursive = true;
      extraArgs = [
        "--skip-parent"
      ];
    };
    commands.backup-var-lib = {
      source = "rpool/nixos/var/lib";
      target = "backup/var_lib";
      service = {
        after = [ "syncoid-backup-data.service" ];
        wants = [ "syncoid-backup-data.service" ];
      };
      recursive = false;
      extraArgs = [
        "--skip-parent"
      ];
    };
  };

  ### Restic
  sops.secrets.restic_env = { };
  sops.secrets.restic_repo = { };
  sops.secrets.restic_password = { };
  sops.secrets.restic_local_repo = { };
  sops.secrets.restic_local_password = { };

  services.restic = {
    backups.homeserver = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile = "${config.sops.secrets.restic_repo.path}";
      passwordFile = "${config.sops.secrets.restic_password.path}";
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
      checkOpts = [
        "--with-cache"
        "--read-data-subset=1%"
      ];
    };
    backups.local = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile = "${config.sops.secrets.restic_local_repo.path}";
      passwordFile = "${config.sops.secrets.restic_local_password.path}";
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
        "/var/lib/private/open-webui/*"
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
      checkOpts = [
        "--with-cache"
        "--read-data-subset=1%"
      ];
    };
  };
}
