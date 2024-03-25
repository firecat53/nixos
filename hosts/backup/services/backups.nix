{
  # Backup user for initiating pull backups from other servers
  users.users.backup = {
    isNormalUser = true;
    uid = 20001;
    group = "root";
    home = "/var/lib/backup";
    createHome = true;
    # password: backup
    initialHashedPassword = "$6$Qw7LgzXEL42Q1s0U$UplFl3gpdhQmrmNNHmVt9Bxc4XByH1vBGX95b0ujumaH.V7cPKXkRtqt27vyG591tYfw/0PMkUqplETmswP.t/";
  };

  ### Sanoid
  services.sanoid = {
    enable = true;
    datasets."backuppool/homeserver/data" = {
      useTemplate = ["data"];
      process_children_only = true;
      recursive = true;
      autosnap = false;
      autoprune = true;
    };
    datasets."backuppool/homeserver/var/lib" = {
      useTemplate = ["data"];
      process_children_only = false;
      autosnap = false;
      autoprune = true;
    };
    datasets."backuppool/homeserver/downloads" = {
      useTemplate = ["downloads"];
      process_children_only = false;
    };
    templates."data" = {
      hourly = 48;
      daily = 30;
      monthly = 6;
      yearly = 0;
    };
    templates."downloads" = {
      hourly = 0;
      daily = 2;
      monthly = 0;
      yearly = 0;
    };
  };

  ### Syncoid
  services.syncoid = {
    enable = true;
    user = "backup";
    sshKey = "/etc/ssh/backup";
    commonArgs = [
      "--no-privilege-elevation"
      "--no-sync-snap"
      "--sshoption=StrictHostKeyChecking=no"  # TODO - one of the systemd hardening options is causing this
    ];
    interval = "*-*-* *:30:00";
    commands.backuppool-homeserver-var-lib = {
      source = "backup@192.168.200.101:rpool/nixos/var/lib";
      target = "backuppool/homeserver/var/lib";
    };
    commands.backuppool-homeserver-downloads = {
      source = "backup@192.168.200.101:downloadpool/downloads";
      target = "backuppool/homeserver/downloads";
    };
    commands.backuppool-homeserver-data = {
      source = "backup@192.168.200.101:rpool/data";
      target = "backuppool/homeserver/data";
      recursive = true;
      extraArgs = [
        "--skip-parent"
      ];
    };
    commands.backuppool-vps = {
      source = "backup@firecat53.com:datapool";
      target = "backuppool/vps";
      recursive = true;
      extraArgs = [
        "--skip-parent"
      ];
    };
  };
}
