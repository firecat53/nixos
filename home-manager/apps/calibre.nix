{
  config,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.calibre
  ];
  programs.bash.profileExtra = ''
    export CALIBRE_OVERRIDE_DATABASE_PATH=${config.home.homeDirectory}/.local/tmp/calibre/metadata.db
  '';
}
