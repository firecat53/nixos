{
  config,
  ...
}:
{
  accounts.email.accounts."firecat53.net".neomutt = {
    enable = true;
    extraMailboxes = [
      "Archive"
      "Drafts"
      "Sent"
      "Spam"
      "Trash"
      "Scheduled"
      "forwebmaster"
    ];
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
      abort_nosubject = "no";
      arrow_cursor = "yes";
      auto_tag = "yes";
      beep = "no";
      beep_new = "yes";
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
      move = "no";
      pager_context = "1";
      pager_index_lines = "8";
      pager_stop = "yes";
      pgp_default_key = ''"${config.accounts.email.accounts."firecat53.net".gpg.key}"'';
      query_command = ''"khard email --parsable %s"'';
      reply_to = "yes";
      reverse_name = "yes";
      sleep_time = "0";
      smart_wrap = "yes";
      sort_aux = "reverse-last-date-received";
      sort_re = "no";
      status_on_top = "yes";
      strict_threads = "yes";
      thorough_search = "yes";
      tilde = "yes";
      timeout = "15";
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
      {
        map = [ "index" ];
        key = "zo";
        action = "collapse-thread";
      }
      {
        map = [ "index" ];
        key = "zc";
        action = "collapse-thread";
      }
      {
        map = [ "index" ];
        key = "zM";
        action = "collapse-all";
      }
      {
        map = [ "attach" ];
        key = "<return>";
        action = "view-mailcap";
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
        map = [ "index" ];
        key = "\\ev";
        action = "change-vfolder";
      }
      {
        map = [
          "index"
          "pager"
        ];
        key = "\\et";
        action = "modify-labels";
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
        action = "<pipe-message>khard add-email<enter>";
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
        key = "D";
        action = "<save-message>=Trash<enter>";
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
        key = "M";
        action = "<shell-escape>notmuch new<enter>";
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
      # Only show the headers worth reading
      ignore *
      unignore from: to: cc: date: subject:

      auto_view text/html
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
    text/html; xdg-open %s; nametemplate=%s.html
    text/html; w3m -I %{charset} -T text/html -dump %s; copiousoutput; nametemplate=%s.html
    application/pdf; zathura %s
    image/*; imv %s
    video/*; mpv %s
    audio/*; mpv %s
    application/msword; libreoffice %s
    application/vnd.ms-excel; libreoffice %s
    application/vnd.oasis.opendocument.*; libreoffice %s
    application/vnd.openxmlformats-officedocument.*; libreoffice %s
  '';
}
