{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mimeDefaults = lib.mkOption {
    type = with lib.types; attrsOf (listOf str);
    default = { };
    example = {
      "imv-dir.desktop" = [ "image/png" ];
    };
    description = "Mime types each desktop entry should open by default.";
  };

  config = {
    # Pinned so another package registering first (calibre did) can't take
    # them over. Apps with their own module set their types there instead.
    mimeDefaults = {
      "writer.desktop" = [
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.text-template"
        "application/vnd.oasis.opendocument.text-flat-xml"
        "application/msword"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
        "application/vnd.ms-word.document.macroenabled.12"
        "application/vnd.ms-word.template.macroenabled.12"
        "application/rtf"
        "text/rtf"
      ];
      "calc.desktop" = [
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.spreadsheet-template"
        "application/vnd.oasis.opendocument.spreadsheet-flat-xml"
        "application/vnd.ms-excel"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
        "application/vnd.ms-excel.sheet.macroenabled.12"
        "application/vnd.ms-excel.sheet.binary.macroenabled.12"
        "text/csv"
        "text/tab-separated-values"
      ];
      "impress.desktop" = [
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.oasis.opendocument.presentation-template"
        "application/vnd.oasis.opendocument.presentation-flat-xml"
        "application/vnd.ms-powerpoint"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        "application/vnd.openxmlformats-officedocument.presentationml.template"
        "application/vnd.ms-powerpoint.presentation.macroenabled.12"
        "application/vnd.ms-powerpoint.slideshow.macroenabled.12"
      ];
      "draw.desktop" = [
        "application/vnd.oasis.opendocument.graphics"
        "application/vnd.oasis.opendocument.graphics-template"
        "application/vnd.visio"
      ];
      "org.pwmt.zathura.desktop" = [ "application/pdf" ];
      "org.pwmt.zathura-cb.desktop" = [
        "application/x-cbz"
        "application/x-cbr"
        "application/x-cb7"
      ];
      "org.pwmt.zathura-djvu.desktop" = [ "image/vnd.djvu" ];
    };

    # Set in place, not via xdg.mimeApps, which would make mimeapps.list a
    # read-only symlink that firefox and others can't write to. Unpinned types
    # go to the first mimeinfo.cache entry, or firefox if there is none.
    home.activation.mimeDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      lib.concatStrings (
        lib.mapAttrsToList (app: types: ''
          run ${pkgs.xdg-utils}/bin/xdg-mime default ${app} ${lib.escapeShellArgs types}
        '') config.mimeDefaults
      )
    );
  };
}
