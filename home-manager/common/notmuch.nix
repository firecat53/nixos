{
  config,
  ...
}:
let
  maildir = config.accounts.email.accounts."firecat53.net".maildir.path;
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
        name = "Last 7 days";
        query = "date:7d..";
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
    search.excludeTags = [
      "trash"
      "spam"
      "deleted"
    ];
    hooks.postNew = ''
      # Folder-derived tags, re-synced every run so moved mail is retagged
      for pair in inbox:Inbox sent:Sent archive:Archive drafts:Drafts spam:Spam trash:Trash; do
        tag=''${pair%%:*}
        dir=''${pair##*:}
        notmuch tag +"$tag" -- folder:"${maildir}/$dir" and not tag:"$tag"
        notmuch tag -"$tag" -- tag:"$tag" and not folder:"${maildir}/$dir"
      done
      notmuch tag -new -- tag:new
    '';
  };

  # Mail arrives via syncthing, so nothing else triggers indexing
  systemd.user.services.notmuch-new = {
    Unit.Description = "Index new mail with notmuch";
    Service = {
      Type = "oneshot";
      Environment = "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config";
      ExecStart = "${config.programs.notmuch.package}/bin/notmuch new --quiet";
    };
  };
  systemd.user.timers.notmuch-new = {
    Unit.Description = "Index new mail with notmuch";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # The xapian database is per-machine
  home.file."mail/.stignore".text = ''
    .notmuch
  '';
}
