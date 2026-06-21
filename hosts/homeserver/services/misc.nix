# 1. Memories RSS feed
# 2. Picture copy service for cameras
# 3. Prometheus user service exporter
{
  config,
  pkgs,
  ...
}:
{
  systemd.timers."memories" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "5m";
      Unit = "memories.service";
    };
  };
  systemd.services."memories" = {
    script = ''
      ${pkgs.podman}/bin/podman run --rm \
      -v /home/firecat53/docs/family/scott/wiki/diary:/data/journal \
      -v /mnt/media/pictures/Family\ Pictures:/data/pictures \
      -v /srv/rss:/srv/rss \
      memories
    '';
    path = [
      pkgs.podman
      pkgs.zfs
    ];
  };
  systemd.timers."picture_copy" = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "3h";
      Unit = "picture_copy.service";
    };
  };
  systemd.services."picture_copy" = {
    script = ''
      set +e
      ${pkgs.exiftool}/bin/exiftool -o . '-Directory<DateTimeOriginal' '-Directory<MediaCreateDate' '-Directory<TimeStamp' -d "/mnt/media/pictures/Family Pictures/%Y/%Y - %B/" -ext jpg -ext png -ext heic -ext tif -ext jpeg -r -P /mnt/media/cameras/ 2>/dev/null
      ${pkgs.exiftool}/bin/exiftool -o . '-Directory<DateTimeOriginal' '-Directory<MediaCreateDate' -d "/mnt/media/video/Family/%Y/%Y - %B/" -ext mp4 -ext avi -ext 3gp -r -P /mnt/media/cameras/ 2>/dev/null
    '';
    path = [ pkgs.exiftool ];
    serviceConfig = {
      User = "firecat53";
      SuccessExitStatus = [ 1 ]; # Exiftool errors on file exists when it tries to copy
      WorkingDirectory = "/home/firecat53/.local/tmp/untagged";
    };
  };

  # Textfile directory (/var/lib/prometheus-node-exporter-text) is created by
  # the shared modules/servers/prometheus-exporters.nix.

  # Export user systemd service states for prometheus
  systemd.services.prometheus-user-services-exporter = {
    description = "Export firecat53 user systemd service states to Prometheus";
    script = ''
      ${config.systemd.package}/bin/systemctl --user list-units --all --output=json | \
        ${pkgs.jq}/bin/jq -r '.[] | select(.unit | endswith(".service")) | "node_systemd_user_unit_state{name=\"" + .unit + "\", state=\"" + .active + "\", load=\"" + .load + "\"} " + (if .active == "failed" then "1" else "0" end)' \
        > /var/lib/prometheus-node-exporter-text/user_services.prom.$$
      ${pkgs.coreutils}/bin/mv /var/lib/prometheus-node-exporter-text/user_services.prom.$$ /var/lib/prometheus-node-exporter-text/user_services.prom
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "firecat53";
    };
    environment = {
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  systemd.timers.prometheus-user-services-exporter = {
    description = "Timer for prometheus user services exporter";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };
}
