{
  config,
  inputs,
  ...
}:
let
  userHome = "${config.home.homeDirectory}";
in
{
  imports = [ inputs.chroncal.homeModules.chroncal ];

  programs.chroncal = {
    enable = true;
    # unset means `service run` only fires alarms and never syncs
    settings.sync.interval = "15m";
  };

  # Declarative equivalent of `chroncal service install`, which would bake a
  # store path into an imperative unit file
  systemd.user.services.chroncal-alarm = {
    Unit.Description = "chroncal alarms and CalDAV sync";
    Service = {
      Type = "oneshot";
      ExecStart = "${config.programs.chroncal.package}/bin/chroncal service run";
    };
  };
  systemd.user.timers.chroncal-alarm = {
    Unit.Description = "chroncal alarm timer";
    Timer = {
      OnCalendar = "*-*-* *:*:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.khal = {
    enable = true;
    locale = {
      timeformat = "%H:%M";
      dateformat = "%Y-%m-%d";
      longdateformat = "%Y-%m-%d";
      datetimeformat = "%Y-%m-%d %H:%M";
      longdatetimeformat = "%Y-%m-%d %H:%M";
      firstweekday = 6;
    };
  };
  programs.khard = {
    enable = true;
    settings = {
      "contact table" = {
        display = "first_name";
        group_by_addressbook = false;
        reverse = false;
        show_nicknames = false;
        show_uids = true;
        sort = "last_name";
        localize_dates = true;
        preferred_phone_number_type = [
          "pref"
          "cell"
          "home"
        ];
        preferred_email_address_type = [
          "pref"
          "work"
          "home"
        ];
      };
      general = {
        debug = false;
        default_action = "list";
        editor = [
          "nvim"
          "-i"
          "NONE"
        ];
        merge_editor = "nvim -d";
      };
      vcard = {
        skip_unparsable = false;
      };
    };
  };

  accounts.calendar.accounts = {
    calendars = {
      khal = {
        enable = true;
        type = "discover";
      };
      local = {
        path = "${userHome}/.local/share/nextcloud/calendars";
        type = "filesystem";
        fileExt = ".ics";
      };
    };
  };
  accounts.contact.accounts = {
    contacts = {
      khard = {
        enable = true;
        # vdirsyncer syncs each nextcloud collection into its own subdir of
        # local.path, so point khard at the collection, not the sync root
        addressbooks = [ "contacts" ];
      };
      local = {
        path = "${userHome}/.local/share/nextcloud/contacts";
        type = "filesystem";
        fileExt = ".vcf";
      };
    };
    wife = {
      khard.enable = true;
      local = {
        path = "${userHome}/.local/share/nextcloud/contacts/wife";
        type = "filesystem";
        fileExt = ".vcf";
      };
    };
  };
}
