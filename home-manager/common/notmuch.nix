{
  config,
  lib,
  mailFolders,
  ...
}:
let
  acct = config.accounts.email.accounts."firecat53.net";
  maildir = acct.maildir.path;
  excludeTags = [
    "trash"
    "spam"
    "deleted"
  ];
  # Naming an excluded tag in a query cancels the exclusion for it, so a query
  # matching (anyExcluded or not anyExcluded) opts out of exclusion entirely
  anyExcluded = lib.concatMapStringsSep " or " (t: "tag:${t}") excludeTags;
in
{
  accounts.email.accounts."firecat53.net".notmuch = {
    enable = true;
    neomutt.virtualMailboxes = [
      {
        name = "Unread";
        query = "tag:unread";
      }
      {
        name = "Flagged";
        query = "tag:flagged";
      }
      {
        # Spans every folder, spam and trash included
        name = "Last 7 days";
        query = "date:7d.. and (${anyExcluded} or not (${anyExcluded}))";
      }
    ];
  };

  programs.notmuch = {
    enable = true;
    # unread/flagged/replied/draft/deleted come from the maildir flags instead
    new.tags = [ "new" ];
    new.ignore = [
      ".stfolder"
      ".stignore"
      ".stversions"
      "/.*[.]syncthing[.].*[.]tmp$/"
    ];
    search.excludeTags = excludeTags;
    # Folder-derived tags, re-synced every run so moved mail is retagged
    hooks.postNew =
      lib.concatStrings (
        lib.mapAttrsToList (tag: dir: ''
          notmuch tag +${tag} -- folder:"${maildir}/${dir}" and not tag:${tag}
          notmuch tag -${tag} -- tag:${tag} and not folder:"${maildir}/${dir}"
        '') mailFolders
      )
      + ''
        notmuch tag -new -- tag:new
      '';
  };

  # Mail arrives via syncthing, so nothing else triggers indexing
  systemd.user.services.notmuch-new = {
    Unit = {
      Description = "Index new mail with notmuch";
      # Reading mail retitles maildir files, so the path unit can fire in bursts
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      Environment = "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config";
      ExecStart = "${config.programs.notmuch.package}/bin/notmuch new --quiet";
    };
  };
  # inotify only reports live changes, so the timer covers mail that landed
  # while the session was down
  systemd.user.paths.notmuch-new = {
    Unit.Description = "Watch the maildir for mail delivered by syncthing";
    Path.PathModified = lib.concatMap (dir: [
      "${acct.maildir.absPath}/${dir}/cur"
      "${acct.maildir.absPath}/${dir}/new"
    ]) (lib.attrValues mailFolders);
    Install.WantedBy = [ "paths.target" ];
  };
  systemd.user.timers.notmuch-new = {
    Unit.Description = "Index new mail with notmuch";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "60m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # The xapian database is per-machine
  home.file."mail/.stignore".text = ''
    .notmuch
  '';
}
