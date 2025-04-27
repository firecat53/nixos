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
    frequency = "*:0/10";
  };
  accounts.calendar.accounts = {
    calendars = {
      local = {
        path = "${home}/docs/family/scott/src/nextcloud/calendars";
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
        conflictResolution = null;
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
        path = "${home}/docs/family/scott/src/nextcloud/contacts";
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
