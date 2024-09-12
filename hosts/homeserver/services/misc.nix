# 1. Memories RSS feed
# 2. Picture copy service for cameras
{
  pkgs,
  ...
}:{
  systemd.timers."memories" = {
    wantedBy = ["timers.target"];
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
    path = [pkgs.podman pkgs.zfs];
  };
  systemd.timers."picture_copy" = {
    enable = true;
    wantedBy = ["timers.target"];
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
    path = [pkgs.exiftool];
    serviceConfig = {
      User = "firecat53";
      SuccessExitStatus = [ 1 ]; # Exiftool errors on file exists when it tries to copy
      WorkingDirectory = "/home/firecat53/.local/tmp/untagged";
    };
  };
}
