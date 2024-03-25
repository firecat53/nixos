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
      OnCalendar = "daily";
      Unit = "picture_copy.service";
    };
  };
  systemd.services."picture_copy" = {
    script = "${pkgs.python3}/bin/python3 /home/firecat53/docs/family/scott/src/scripts.git/bin/pix.py";
    path = [pkgs.python3 pkgs.rsync pkgs.exiftool];
    serviceConfig = {
      User = "firecat53";
    };
  };
}
