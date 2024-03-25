{
  config,
  sops,
  ...
}:{
  # For pull backups from backup server
  users.users.backup = {
    isNormalUser = true;
    uid = 20001;
    group = "root";
    home = "/var/lib/backup";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup"
    ];
    # password: backup
    initialHashedPassword = "$6$Qw7LgzXEL42Q1s0U$UplFl3gpdhQmrmNNHmVt9Bxc4XByH1vBGX95b0ujumaH.V7cPKXkRtqt27vyG591tYfw/0PMkUqplETmswP.t/";
  };

  ### Sanoid
  services.sanoid = {
    enable = true;
    datasets."datapool" = {
      useTemplate = ["data"];
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
  };

  ### Restic
  sops.secrets.restic_env = {};
  sops.secrets.restic_repo = {};
  sops.secrets.restic_password = {};

  services.restic = {
    backups.vps = {
      user = "root";
      environmentFile = "${config.sops.secrets.restic_env.path}";
      repositoryFile =  "${config.sops.secrets.restic_repo.path}";
      passwordFile =  "${config.sops.secrets.restic_password.path}";
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
