{
  config,
  ...
}:
let
  userHome = "${config.home.homeDirectory}";
in
{
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
      khard.enable = true;
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
