{
  config,
  pkgs,
  ...
}:{
  xdg = {
    enable = true;
  };

  home.packages = [ pkgs.xdg-utils ];
  xdg.mime.enable = true;

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
      XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/.local/tmp";
    };
  };
}
