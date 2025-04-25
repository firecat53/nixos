{
  config,
  lib,
  ...
}:
{
  sops.secrets.nextcloud-caldav-pw = {
    mode = "0440";
    owner = "firecat53";
    group = "users";
  };

  services.vdirsyncer.enable = true;
  services.vdirsyncer.jobs.nextcloud = {
    enable = true;
    user = "firecat53";
    group = "users";
    forceDiscover = false;
    config.storages = {
      calendars_local = {
        path = "/home/firecat53/docs/family/scott/src/nextcloud/calendars";
        type = "filesystem";
        fileext = ".ics";
      };
      calendars_remote = {
        "password.fetch" = [
          "command"
          "cat"
          "${config.sops.secrets.nextcloud-caldav-pw.path}"
        ];
        type = "caldav";
        url = "https://nc.firecat53.com";
        username = "firecat53";
      };
      contacts_local = {
        path = "/home/firecat53/docs/family/scott/src/nextcloud/contacts";
        type = "filesystem";
        fileext = ".vcf";
      };
      contacts_remote = {
        "password.fetch" = [
          "command"
          "cat"
          "${config.sops.secrets.nextcloud-caldav-pw.path}"
        ];
        type = "carddav";
        url = "https://nc.firecat53.com";
        username = "firecat53";
      };
    };
    config.pairs = {
      calendars = {
        a = "calendars_local";
        b = "calendars_remote";
        collections = [
          "from a"
          "from b"
        ];
        metadata = [
          "color"
          "displayname"
        ];
      };
      contacts = {
        a = "contacts_local";
        b = "contacts_remote";
        collections = [
          "from a"
          "from b"
        ];
        metadata = [ "displayname" ];
      };
    };
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "10m";
    };
  };
  # Allow writing to /home/firecat53
  systemd.services."vdirsyncer@nextcloud".serviceConfig = {
    ProtectHome = lib.mkForce false;
  };
}
