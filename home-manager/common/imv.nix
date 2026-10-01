{
  # imv-dir opens the whole directory, starting at the chosen image
  mimeDefaults."imv-dir.desktop" = [
    "image/jpeg"
    "image/jpg"
    "image/pjpeg"
    "image/png"
    "image/x-png"
    "image/gif"
    "image/bmp"
    "image/x-bmp"
    "image/tiff"
    "image/heif"
    "image/avif"
    "image/jxl"
    "image/webp"
    "image/svg+xml"
    "image/qoi"
  ];
  programs.imv = {
    enable = true;
    settings = {
      binds = {
        n = "next";
        p = "prev";
        v = "overlay";
        "<Ctrl+r>" = "rotate by 90";
      };
    };
  };
}
