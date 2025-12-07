# Syncthing
{
  pkgs,
  ...
}:
{
  services.syncthing = {
    enable = true;
    user = "firecat53";
    group = "firecat53";
    dataDir = "/home/firecat53/.local/state/syncthing";
    configDir = "/home/firecat53/.config/syncthing";
    openDefaultPorts = true;
    settings = {
      options = {
        relaysEnabled = false;
        urAccepted = 3;
      };
      devices = {
        "backup" = {
          id = "CAKABE3-JTNUTY6-6BJYHGS-7E4Z35Y-SDF5M6H-GLB6Q2G-M6FVISW-Q3AVHQV";
        };
        "homeserver" = {
          id = "3WS2YZY-BCZNA5N-ZNBCA5G-JNPVFLA-FJQI2VQ-BAM5LK5-UVLWWGM-4DWTRQM";
          addresses = [
            "quic://firecat53.net:22000"
            "tcp://firecat53.net:22000"
          ];
        };
        "pangolin" = {
          id = "2IEK3MX-PXVTZIG-D5OP4V3-LYEK3FY-IK4QWIM-K67K65A-ZI62LHH-O3R47Q7";
        };
        "scott-cell" = {
          id = "6LDX7IF-D2MWKOW-APU3AUX-WXNBWFG-PNIUAPB-QKTWZHF-7MKLPBI-M6E6AQE";
        };
        "scott-office" = {
          id = "4L73OQJ-4T6KOAR-5TJLKKY-ANBRCCB-KAOBFM7-LWVGPFK-QQ643GT-H4LIXAH";
        };
        "vps" = {
          id = "EPFW7TB-MUV25YB-P2SM66L-ENLRREJ-UJIRELD-QC2FWM4-RVSLFJY-7YWXCQ6";
          addresses = [
            "quic://firecat53.com:22000"
            "tcp://firecat53.com:22000"
          ];
        };
      };
      folders = {
        "camera-scotty" = {
          path = "/home/firecat53/media/cameras/scotty";
          devices = [
            "homeserver"
            "scott-cell"
            "scott-office"
          ];
          id = "camera-scotty";
        };
        "docs-scotty" = {
          path = "/home/firecat53/docs";
          devices = [
            "homeserver"
            "scott-cell"
            "scott-office"
          ];
          id = "docs";
          ignorePerms = true;  # Allow ACLs
        };
        "file_xfer" = {
          path = "/home/firecat53/.local/tmp/file_xfer";
          devices = [
            "homeserver"
            "scott-cell"
            "scott-office"
          ];
          id = "file_xfer";
        };
        "mail" = {
          path = "/home/firecat53/mail";
          devices = [
            "homeserver"
            "scott-office"
          ];
          id = "sdgpi-zh6rd";
        };
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = [
            "backup"
            "homeserver"
            "pangolin"
            "scott-office"
            "vps"
          ];
          id = "smqlq-yhrua";
          type = "sendreceive";
        };
        "shared" = {
          path = "/home/firecat53/shared";
          devices = [
            "homeserver"
            "scott-cell"
            "scott-office"
            "vps"
          ];
          id = "shared";
          ignorePerms = true;  # Allow ACLs
        };
        "srv" = {
          path = "/home/firecat53/.local/srv";
          devices = [
            "homeserver"
            "scott-office"
            "vps"
          ];
          id = "srv";
        };
        "wallpaper" = {
          path = "/home/firecat53/media/wallpaper";
          devices = [
            "homeserver"
            "scott-office"
          ];
          id = "wallpaper";
        };
      };
    };
  };
  # Syncthing cli tool stc
  environment.systemPackages = [ pkgs.stc-cli ];
}
