{
  config,
  lib,
  mailFolders,
  pkgs,
  ...
}:
let
  acct = config.accounts.email.accounts."firecat53.net";
  # reverse_name picks the From: address by matching against these
  alternates = lib.concatMapStringsSep " " (a: "'^${lib.escapeRegex a}$'") (
    [ acct.address ] ++ acct.aliases
  );
  # neomutt unlinks its temp file as soon as the viewer exits, which xdg-open
  # does immediately — so hand the browser a copy that outlives it
  openHtml = pkgs.writeShellScript "neomutt-open-html" ''
    dir="''${XDG_RUNTIME_DIR:-/tmp}"
    ${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -name 'neomutt-*.html' -mmin +60 -delete
    out=$(${pkgs.coreutils}/bin/mktemp --tmpdir="$dir" --suffix=.html neomutt-XXXXXXXX)
    ${pkgs.coreutils}/bin/cp -- "$1" "$out"
    exec ${pkgs.util-linux}/bin/setsid -f ${pkgs.xdg-utils}/bin/xdg-open "$out"
  '';
in
{
  accounts.email.accounts."firecat53.net".neomutt = {
    enable = true;
    # Inbox is the spoolfile, so it's already a mailbox
    extraMailboxes = lib.attrValues (removeAttrs mailFolders [ "inbox" ]);
  };

  programs.neomutt = {
    enable = true;
    editor = "nvim +':set textwidth=77' +':set wrap' +/^$";
    checkStatsInterval = 60;
    sidebar = {
      enable = true;
      width = 24;
    };

    settings = {
      # Prompt when the body mentions an attachment but none is attached
      abort_noattach = "ask-yes";
      abort_nosubject = "no";
      arrow_cursor = "yes";
      auto_tag = "yes";
      beep = "no";
      beep_new = "yes";
      # Keep threads with unread mail open, since every folder opens collapsed
      collapse_unread = "no";
      confirm_append = "no";
      edit_headers = "yes";
      fast_reply = "yes";
      help = "no";
      include = "ask-no";
      index_format = ''"%4C %?M?(%03M)&     ? %Z %{%Y %b %d} %-15.15L %s"'';
      mailcap_path = ''"${config.xdg.configHome}/neomutt/mailcap"'';
      mark_old = "no";
      markers = "no";
      menu_scroll = "yes";
      # search.excludeTags only applies to the notmuch CLI; neomutt needs its own
      nm_exclude_tags = ''"${lib.concatStringsSep "," config.programs.notmuch.search.excludeTags}"'';
      # Return whole threads from a vfolder query, not just the matches
      nm_query_type = ''"threads"'';
      pager_context = "1";
      pager_index_lines = "8";
      pager_stop = "yes";
      pgp_default_key = ''"${acct.gpg.key}"'';
      query_command = ''"khard email --parsable -a contacts-contacts %s"'';
      reply_to = "yes";
      reverse_name = "yes";
      sleep_time = "0";
      sort_aux = "reverse-last-date-received";
      status_on_top = "yes";
      strict_threads = "yes";
      tilde = "yes";
      timeout = "15";
      uncollapse_jump = "yes";
      wrap = "85";
    };

    binds = [
      # Free up 'g' as a prefix for gg/gi/ga/gs/gr
      {
        map = [
          "index"
          "pager"
        ];
        key = "g";
        action = "noop";
      }
      {
        map = [ "pager" ];
        key = "<up>";
        action = "previous-line";
      }
      {
        map = [ "pager" ];
        key = "<down>";
        action = "next-line";
      }
      # Scroll the open message: J/K by a line, [/] by a page. In the pager
      # this takes J/K away from next/previous message; the index still has them.
      {
        map = [ "pager" ];
        key = "K";
        action = "previous-line";
      }
      {
        map = [ "pager" ];
        key = "J";
        action = "next-line";
      }
      {
        map = [ "pager" ];
        key = "[";
        action = "previous-page";
      }
      {
        map = [ "pager" ];
        key = "]";
        action = "next-page";
      }
      {
        map = [ "pager" ];
        key = "gg";
        action = "top";
      }
      {
        map = [ "pager" ];
        key = "G";
        action = "bottom";
      }
      {
        map = [ "index" ];
        key = "gg";
        action = "first-entry";
      }
      {
        map = [ "index" ];
        key = "G";
        action = "last-entry";
      }
      # collapse-thread is a toggle, so it's 'za' rather than a zo/zc pair
      {
        map = [ "index" ];
        key = "za";
        action = "collapse-thread";
      }
      {
        map = [ "index" ];
        key = "zM";
        action = "collapse-all";
      }
      # 'd' is the archive macro, so delete needs a home of its own. $trash is
      # set, so this moves to Trash rather than purging.
      {
        map = [
          "index"
          "pager"
        ];
        key = "D";
        action = "delete-message";
      }
      {
        map = [ "editor" ];
        key = "<Tab>";
        action = "complete-query";
      }
      {
        map = [ "editor" ];
        key = "\\CT";
        action = "complete";
      }

      # Sidebar
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\Ck";
        action = "sidebar-prev";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\Cj";
        action = "sidebar-next";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\Co";
        action = "sidebar-open";
      }

      # Notmuch.
      {
        map = [ "index" ];
        key = "S";
        action = "vfolder-from-query";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\ee";
        action = "entire-thread";
      }
    ];

    macros = [
      {
        map = [
          "index"
          "pager"
        ];
        key = "b";
        action = "<pipe-message>urlscan -d<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "A";
        action = "<pipe-message>khard add-email -a contacts-contacts<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "gi";
        action = "<change-folder>=Inbox<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "ga";
        action = "<change-folder>=Archive<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "gs";
        action = "<change-folder>=Sent<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "gr";
        action = "<group-reply>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "H";
        action = "<change-folder>?";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "B";
        action = "<limit>~b ";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "d";
        action = "<save-message>=Archive<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "X";
        action = "<save-message>=Spam<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\Cr";
        action = "<tag-pattern>all<enter><tag-prefix><clear-flag>N<untag-pattern>all<enter>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\Cb";
        action = "<bounce-message>";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\eb";
        action = "<enter-command>toggle sidebar_visible<enter><refresh>";
      }
    ];

    extraConfig = ''
      # Recognize the aliases as our own, for reverse_name and ~p searches
      alternates ${alternates}

      # Only show the headers worth reading
      ignore *
      unignore from: to: cc: date: subject:

      auto_view text/html text/calendar application/ics
      # alternative_order appends, so clear the default list first
      unalternative_order *
      alternative_order text/plain text/enriched text/html
      mime_lookup application/octet-stream

      folder-hook . push "<collapse-all>"

      # Catppuccin mocha, via the terminal palette
      color normal        default default
      color index         color2 default ~N
      color index         color1 default ~F
      color index         color13 default ~T
      color index         color1 default ~D
      color attachment    color5 default
      color signature     color8 default
      color search        color4 default

      color indicator     default color8
      color error         color1 default
      color status        color15 default
      color tree          color15 default
      color tilde         color15 default

      color hdrdefault    color13 default
      color header        color13 default "^From:"
      color header        color13 default "^Subject:"

      color quoted        color15 default
      color quoted1       color7 default
      color quoted2       color8 default
      color quoted3       color0 default
      color quoted4       color0 default
      color quoted5       color0 default

      color body          color2 default  [\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+
      color body          color2 default  (https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+
      color body          color4 default  (^|[[:space:]])\\*[^[:space:]]+\\*([[:space:]]|$)
      color body          color4 default  (^|[[:space:]])_[^[:space:]]+_([[:space:]]|$)
      color body          color4 default  (^|[[:space:]])/[^[:space:]]+/([[:space:]]|$)

      color sidebar_flagged color1 default
      color sidebar_new     color10 default
    '';
  };

  xdg.configFile."neomutt/mailcap".text = ''
    # test= keeps the GUI viewers from firing on a bare tty (neomutt over ssh),
    # letting any copiousoutput entry below take over instead
    text/html; ${openHtml} %s; nametemplate=%s.html; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    text/html; w3m -I %{charset} -T text/html -dump %s; copiousoutput; nametemplate=%s.html
    # Render meeting invites instead of dumping raw iCalendar
    text/calendar; khal printics %s; copiousoutput; nametemplate=%s.ics
    application/ics; khal printics %s; copiousoutput; nametemplate=%s.ics
    application/pdf; zathura %s; nametemplate=%s.pdf; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    image/*; imv %s; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    video/*; mpv %s; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    audio/*; mpv %s
    # atool and libreoffice both pick their format from the file extension, so
    # every entry below needs a nametemplate to survive neomutt's temp file
    application/zip; atool -l %s; copiousoutput; nametemplate=%s.zip
    application/x-7z-compressed; atool -l %s; copiousoutput; nametemplate=%s.7z
    application/x-tar; atool -l %s; copiousoutput; nametemplate=%s.tar
    application/gzip; atool -l %s; copiousoutput; nametemplate=%s.tar.gz
    application/msword; libreoffice %s; nametemplate=%s.doc; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.ms-excel; libreoffice %s; nametemplate=%s.xls; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.ms-powerpoint; libreoffice %s; nametemplate=%s.ppt; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.openxmlformats-officedocument.wordprocessingml.document; libreoffice %s; nametemplate=%s.docx; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; libreoffice %s; nametemplate=%s.xlsx; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.openxmlformats-officedocument.presentationml.presentation; libreoffice %s; nametemplate=%s.pptx; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.oasis.opendocument.text; libreoffice %s; nametemplate=%s.odt; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.oasis.opendocument.spreadsheet; libreoffice %s; nametemplate=%s.ods; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
    application/vnd.oasis.opendocument.presentation; libreoffice %s; nametemplate=%s.odp; test=test -n "$WAYLAND_DISPLAY$DISPLAY"
  '';
}
