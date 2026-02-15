# Microbin
# accessed vi Pangolin at mb.firecat53.me. Set CORS origin URL in
# `hosts/pangolin/services/pangolin.nix` to the value of MICROBIN_PUBLIC_PATH
{
  config,
  ...
}:
{
  sops.secrets.microbin = { };
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
