{
  pkgs,
  ...
}:{
  home.packages = [
    pkgs.calibre
  ];
  programs.bash.profileExtra = ''
    export CALIBRE_OVERRIDE_DATABASE_PATH=/home/firecat53/.local/tmp/calibre/metadata.db
  '';
}
