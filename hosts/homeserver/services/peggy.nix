# Peggy camera backups
{
  pkgs,
  ...
}:{
  fileSystems = {
    "/mnt/media/cameras-peggy" = {
      device = "rpool/data/cameras-peggy";
      fsType = "zfs";
      options = ["X-mount.mkdir"];
    };
  };

  systemd.timers."picture_copy_peggy" = {
    enable = true;
    wantedBy = ["timers.target"];
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
    path = [pkgs.exiftool];
    serviceConfig = {
      User = "firecat53";
      SuccessExitStatus = [ 1 ]; # Exiftool errors on file exists when it tries to copy
      WorkingDirectory = "/home/firecat53/.local/tmp/untagged-peggy";
    };
  };
}
