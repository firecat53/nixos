# Syncthing
{
  services.syncthing = {
    enable = true;
    user = "firecat53";
    group = "users";
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
          addresses = ["quic://firecat53.net:22000" "tcp://firecat53.net:22000"];
        };
        "scott-cell" = {
          id = "6LDX7IF-D2MWKOW-APU3AUX-WXNBWFG-PNIUAPB-QKTWZHF-7MKLPBI-M6E6AQE";
        };
        "scott-office" = {
          id = "JJEHDJM-7EXVS6I-U5LIV3G-QH56XUA-77WXQZA-PXI4GIF-6ATNTOZ-5JA2FQV";
        };
        "vps" = {
          id = "EPFW7TB-MUV25YB-P2SM66L-ENLRREJ-UJIRELD-QC2FWM4-RVSLFJY-7YWXCQ6";
          addresses = ["quic://firecat53.com:22000" "tcp://firecat53.com:22000"];
        };
      };
      folders = {
        "camera-scotty" = {
          path = "/home/firecat53/media/cameras/scotty";
          devices = ["homeserver" "scott-cell" "scott-office"];
          id = "camera-scotty";
        };
        "docs-scotty" = {
          path = "/home/firecat53/docs";
          devices = ["homeserver" "scott-cell" "scott-office"];
          id = "docs";
        };
        "file_xfer" = {
          path = "/home/firecat53/.local/tmp/file_xfer";
          devices = ["homeserver" "scott-cell" "scott-office"];
          id = "file_xfer";
        };
        "mail" = {
          path = "/home/firecat53/mail";
          devices = ["homeserver" "scott-office"];
          id = "sdgpi-zh6rd";
        };
        "mom_books" = {
          path = "/home/firecat53/.local/tmp/mom_books";
          devices = ["homeserver" "scott-office"];
          id = "quhfj-7uvtc";
        };
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = ["homeserver" "scott-office" "backup" "vps"];
          id = "smqlq-yhrua";
        };
        "shared" = {
          path = "/home/firecat53/shared";
          devices = ["scott-cell" "homeserver" "vps" "scott-office"]; 
          id = "shared";
        };
        "srv" = {
          path = "/home/firecat53/.local/srv";
          devices = ["vps" "homeserver" "scott-office"];
          id = "srv";
        };
        "wallpaper" = {
          path = "/home/firecat53/media/wallpaper";
          devices = ["homeserver" "scott-office"];
          id = "wallpaper";
        };
      };
    };
  };
}
