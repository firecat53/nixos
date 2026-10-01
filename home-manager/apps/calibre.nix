{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.calibre
  ];
  programs.bash.profileExtra = ''
    export CALIBRE_OVERRIDE_DATABASE_PATH=${config.home.homeDirectory}/docs/family/scott/src/state/calibre/metadata.db
  '';
  # Calibre registers its editor first for some ebook types; open them read-only
  home.activation.calibreMimeDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.xdg-utils}/bin/xdg-mime default calibre-ebook-viewer.desktop \
      application/epub+zip application/x-mobi8-ebook
  '';
}
