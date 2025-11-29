# Peggy camera backups
{
  config,
  pkgs,
  ...
}:
{
  fileSystems = {
    "/mnt/media/cameras-peggy" = {
      device = "rpool/data/cameras-peggy";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };
  };

  systemd.timers."picture_copy_peggy" = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "3h";
      Unit = "picture_copy_peggy.service";
    };
  };
  systemd.services."picture_copy_peggy" = {
    script = ''
      ${pkgs.exiftool}/bin/exiftool -o . '-Directory<DateTimeOriginal' '-Directory<MediaCreateDate' '-Directory<TimeStamp' -d "/home/peggy/Pictures/%Y/%Y - %B/" -ext jpg -ext png -ext heic -ext tif -ext jpeg -ext mp4 -ext avi -ext 3gp -r -P /mnt/media/cameras-peggy/ 2>/dev/null
    '';
    path = [ pkgs.exiftool ];
    serviceConfig = {
      User = "firecat53";
      SuccessExitStatus = [ 1 ]; # Exiftool errors on file exists when it tries to copy
      WorkingDirectory = "/home/firecat53/.local/tmp/untagged-peggy";
    };
  };

  # Automatic bitwarden vault backup to /var/backups/
  sops.secrets.bitwarden-clientid-peggy = { };
  sops.secrets.bitwarden-clientsecret-peggy = { };
  sops.secrets.bitwarden-password-peggy = { };

  systemd.services.bitwarden-backup-peggy = {
    description = "Backup Bitwarden vault";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      LoadCredential = [
        "client_id:${config.sops.secrets.bitwarden-clientid-peggy.path}"
        "client_secret:${config.sops.secrets.bitwarden-clientsecret-peggy.path}"
        "password:${config.sops.secrets.bitwarden-password-peggy.path}"
      ];
    };
    script = ''
      STATUS=$(${pkgs.bitwarden-cli}/bin/bw status | ${pkgs.jq}/bin/jq -r '.status')

      if [ "$STATUS" = "unauthenticated" ]; then
        export BW_CLIENTID=$(cat $CREDENTIALS_DIRECTORY/client_id)
        export BW_CLIENTSECRET=$(cat $CREDENTIALS_DIRECTORY/client_secret)
        ${pkgs.bitwarden-cli}/bin/bw login --apikey
      elif [ "$STATUS" != "locked" ]; then
        echo "Error: Unknown vault status: $STATUS"
        exit 1
      fi
      export BW_SESSION=$(${pkgs.bitwarden-cli}/bin/bw unlock \
        --raw \
        --passwordfile=$CREDENTIALS_DIRECTORY/password)

      ${pkgs.bitwarden-cli}/bin/bw sync
      ${pkgs.bitwarden-cli}/bin/bw export \
        --format json \
        --output /var/backups/bitwarden-backup-peggy.json

      ${pkgs.bitwarden-cli}/bin/bw lock
    '';
    path = [ pkgs.bitwarden-cli pkgs.jq ];
  };
  systemd.timers.bitwarden-backup-peggy = {
    description = "Backup Peggy's Bitwarden vault daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
