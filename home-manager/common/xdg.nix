{
  config,
  pkgs,
  ...
}:
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

  mimeDefaults."nvim-view.desktop" = config.xdg.desktopEntries.nvim-view.mimeType;

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
