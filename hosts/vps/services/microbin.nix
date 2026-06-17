# Microbin
# Served locally and exposed at mb.firecat53.me via the VPS Traefik (proxy-me.nix).
{
  config,
  ...
}:
{
  sops.secrets.microbin = { };

  # Microbin is gated behind Authelia (mb.auth = true in registry.nix), but
  # paste *viewing* should stay public. These bypass rules are evaluated before
  # the blanket two_factor rule in authelia.nix; everything not matched here
  # (upload form, create, admin, list, edit, remove) still requires 2FA.
  autheliaBypassRules = [
    {
      domain = "mb.firecat53.me";
      policy = "bypass";
      resources = [
        "^/p/.*$"
        "^/upload/[^/]+$" # /upload/{id} view — bare /upload (create) stays gated
        "^/url/.*$"
        "^/u/.*$"
        "^/raw/.*$"
        "^/qr/.*$"
        "^/file/.*$"
        "^/secure_file/.*$"
        "^/archive/.*$"
        "^/auth/.*$"
        "^/auth_raw/.*$"
        "^/auth_file/.*$"
        "^/static/.*$"
        "^/favicon.ico$"
      ];
    }
  ];

  services.microbin = {
    enable = true;
    passwordFile = "${config.sops.secrets.microbin.path}";
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_ENABLE_BURN_AFTER = "true";
      MICROBIN_ENABLE_READONLY = "true";
      MICROBIN_ENCRYPTION_CLIENT_SIDE = "true";
      MICROBIN_ENCRYPTION_SERVER_SIDE = "true";
      MICROBIN_ETERNAL_PASTA = "true";
      MICROBIN_GC_DAYS = "0";
      MICROBIN_HIGHLIGHTSYNTAX = "true";
      MICROBIN_LIST_SERVER = "false";
      MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = "1024";
      MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = "10000";
      MICROBIN_NO_LISTING = "true";
      MICROBIN_PORT = "8081";
      MICROBIN_PRIVATE = "true";
      MICROBIN_PUBLIC_PATH = "https://mb.firecat53.me";
      MICROBIN_QR = "true";
      MICROBIN_READONLY = "false";
      MICROBIN_WIDE = "true";
    };
  };
}
