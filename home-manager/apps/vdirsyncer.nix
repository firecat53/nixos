{
  config,
  pkgs,
  ...
}:
let
  home = "${config.home.homeDirectory}";
in
{
  sops.secrets.nextcloud-caldav-pw = { };

  programs.vdirsyncer = {
    enable = true;
    statusPath = "${home}/.cache/vdirsyncer/status/";
  };
  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/5";
  };
  systemd.user.timers.vdirsyncer.Timer.RandomizedDelaySec = "1m";
  accounts.calendar.accounts = {
    calendars = {
      local = {
        path = "${home}/.local/share/nextcloud/calendars";
        type = "filesystem";
        fileExt = ".ics";
      };
      remote = {
        type = "caldav";
        userName = "${config.home.username}";
        passwordCommand = [
          "${pkgs.coreutils}/bin/cat"
          "${config.sops.secrets.nextcloud-caldav-pw.path}"
        ];
        url = "https://nc.firecat53.com";
      };
      vdirsyncer = {
        enable = true;
        collections = [
          "from a"
          "from b"
        ];
        conflictResolution = null; # "remote wins" to force sync from nextcloud
        metadata = [
          "color"
          "displayname"
        ];
      };
    };
  };
  accounts.contact.accounts = {
    contacts = {
      local = {
        path = "${home}/.local/share/nextcloud/contacts";
        type = "filesystem";
        fileExt = ".vcf";
      };
      remote = {
        type = "carddav";
        userName = "${config.home.username}";
        passwordCommand = [
          "${pkgs.coreutils}/bin/cat"
          "${config.sops.secrets.nextcloud-caldav-pw.path}"
        ];
        url = "https://nc.firecat53.com";
      };
      vdirsyncer = {
        enable = true;
        collections = [
          "from a"
          "from b"
        ];
        conflictResolution = null;
        metadata = [ "displayname" ];
      };
    };
  };
}
