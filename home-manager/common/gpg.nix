{
  pkgs,
  ...
}:{
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 60480000;
    maxCacheTtl = 60480000;
    defaultCacheTtlSsh = 60480000;
    maxCacheTtlSsh = 60480000;
    enableSshSupport = true;
    grabKeyboardAndMouse = false;
    pinentryPackage = pkgs.pinentry-qt;
  };
  programs.gpg = {
    enable = true;
  };
}
