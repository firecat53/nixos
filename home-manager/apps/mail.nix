{
  config,
  home,
  lib,
  pkgs,
  ...
}:{
  home.packages = with pkgs; [
    isync ## TODO mbsync
    mairix
    mutt
  ];

  services.mbsync = {
    enable = true;
    frequency = "*:0/2";
  };
  systemd.user.services.mbsync = {
    Service = {
      Environment = "PATH=$PATH:${lib.makeBinPath [pkgs.isync]}";
      ExecStart = lib.mkForce "${pkgs.isync}/bin/mbsync -a";
    };
  };

  # Create mairix database directory
  systemd.user.tmpfiles.rules = [
    "d ${config.xdg.dataHome}/mairix 0755 firecat53 firecat53 -"
  ];
  # Create ~/.mairixrc
  home.file.".mairixrc" = {
    text = ''
      base=/home/firecat53/mail
      maildir=firecat4153/archive
      maildir=scottandchrystie/archive
      maildir=firecat53.net/Archive
      mfolder=.search
      database=$XDG_DATA_HOME/mairix/mairix_database
    '';
  };

  systemd.user.services = {
    mairix-index = {
      Unit = {
        Description = "Mairix index";
      };
      Service = {
        ExecStart = "${pkgs.mairix}/bin/mairix";
      };
    };
    mairix-purge = {
      Unit = {
        Description = "Mairix purge";
      };
      Service = {
        ExecStart = "${pkgs.mairix}/bin/mairix -p";
      };
    };
  };
  systemd.user.timers = {
    mairix-index = {
      Unit = {
        Description = "Mairix index timer";
      };
      Timer = {
        OnUnitActiveSec = "1hr";
        OnBootSec = "5m";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
    mairix-purge = {
      Unit = {
        Description = "Mairix purge timer";
      };
      Timer = {
        OnUnitActiveSec = "12hr";
        Persistent = "true";
        OnBootSec = "15m";
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
