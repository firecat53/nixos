{
  lib,
  pkgs,
  ...
}:
{
  systemd.user.services = {
    wallpaper = {
      Unit = {
        Description = "Wallpaper switcher";
        # Start only once sway has exported SWAYSOCK to systemd
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
      };
      Install.WantedBy = [ "sway-session.target" ];
      Service = {
        Environment = "PATH=$PATH:${
          lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils-full
            pkgs.fd
            pkgs.sway
          ]
        }";
        ExecStart = "${pkgs.bash}/bin/sh -c 'cp \"$(${pkgs.fd}/bin/fd . -t file $HOME/media/wallpaper | ${pkgs.coreutils-full}/bin/shuf -n 1)\" /tmp/wall.png && ${pkgs.sway}/bin/swaymsg output \"*\" bg /tmp/wall.png fill'";
      };
    };
  };
  systemd.user.timers = {
    wallpaper = {
      Unit = {
        Description = "Wallpaper switcher";
        PartOf = [ "sway-session.target" ];
      };
      Timer = {
        OnUnitActiveSec = "2m";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}
