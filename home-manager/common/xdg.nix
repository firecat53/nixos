{
  config,
  lib,
  pkgs,
  ...
}:
let
  xdgMime = "${pkgs.xdg-utils}/bin/xdg-mime";
in
{
  xdg = {
    enable = true;
  };

  home.packages = [ pkgs.xdg-utils ];
  xdg.mime.enable = true;

  # Plain text and mail in nvim, in whatever terminal xdg-terminal-exec picks
  xdg.desktopEntries.nvim-view = {
    name = "Neovim (read-only)";
    exec = "${config.xdg.terminal-exec.package}/bin/xdg-terminal-exec ${pkgs.nvim-pkg}/bin/nvim -R %F";
    mimeType = [
      "text/plain"
      "text/markdown"
      "text/x-markdown"
      "message/rfc822"
    ];
    noDisplay = true;
  };

  # Defaults set in place, not via xdg.mimeApps, which would make mimeapps.list
  # a read-only symlink (see neomutt.nix). Without these, xdg-open takes the
  # first mimeinfo.cache entry, which is often calibre, or falls back to firefox.
  home.activation.mimeDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # imv-dir opens the whole directory, starting at the chosen image
    run ${xdgMime} default imv-dir.desktop \
      image/jpeg image/jpg image/pjpeg image/png image/x-png image/gif \
      image/bmp image/x-bmp image/tiff image/heif image/avif image/jxl \
      image/webp image/svg+xml image/qoi
    run ${xdgMime} default writer.desktop \
      application/vnd.oasis.opendocument.text \
      application/vnd.openxmlformats-officedocument.wordprocessingml.document \
      application/vnd.ms-word.document.macroenabled.12 \
      application/msword application/rtf text/rtf
    run ${xdgMime} default org.pwmt.zathura-cb.desktop \
      application/x-cbz application/x-cbr application/x-cb7
    run ${xdgMime} default org.pwmt.zathura-djvu.desktop image/vnd.djvu
    run ${xdgMime} default nvim-view.desktop \
      text/plain text/markdown text/x-markdown message/rfc822
  '';

  xdg.userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}/docs";
    download = "${config.home.homeDirectory}/.local/tmp";
    music = "${config.home.homeDirectory}/media/music";
    pictures = "${config.home.homeDirectory}/media/pictures";
    publicShare = "${config.home.homeDirectory}/.local/srv/";
    videos = "${config.home.homeDirectory}/media/videos";
    templates = "${config.home.homeDirectory}/.local/tmp";
    extraConfig = {
      SCREENSHOTS = "${config.home.homeDirectory}/.local/tmp";
    };
  };
}
