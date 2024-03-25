{
  lib,
  pkgs,
  ...
}:{
  systemd.user.services = {
    wallpaper = {
      Unit = {
        Description = "Wallpaper switcher";
        ConditionEnvironment = "DESKTOP_SESSION=sway";
      };
      Service = {
        Environment = "PATH=$PATH:${lib.makeBinPath [pkgs.bash pkgs.coreutils-full pkgs.fd pkgs.sway]}";
        ExecStart = "${pkgs.bash}/bin/sh -c 'cp \"$(${pkgs.fd}/bin/fd . -t file $HOME/media/wallpaper | ${pkgs.coreutils-full}/bin/shuf -n 1)\" /tmp/wall.png && ${pkgs.sway}/bin/swaymsg output \"*\" bg /tmp/wall.png fill'";
      };
    };
  };
  systemd.user.timers = {
    wallpaper = {
      Unit = {
        Description = "Wallpaper switcher";
      };
      Timer = {
        OnUnitActiveSec = "2m";
        OnBootSec = "1m";
      };
    };
  };
}
