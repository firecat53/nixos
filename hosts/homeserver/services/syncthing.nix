# Syncthing
{
  lib,
  ...
}:{
  services.syncthing = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/home/firecat53/.local/state/syncthing";
    configDir = "/home/firecat53/.config/syncthing";
    openDefaultPorts = true;
    settings = {
      gui = {
        insecureSkipHostcheck = true;
      };
      options = {
        relaysEnabled = false;
        urAccepted = 3;
      };
      devices = {
        "backup" = {
          id = "CAKABE3-JTNUTY6-6BJYHGS-7E4Z35Y-SDF5M6H-GLB6Q2G-M6FVISW-Q3AVHQV";
        };
        "scott-cell" = {
          id = "6LDX7IF-D2MWKOW-APU3AUX-WXNBWFG-PNIUAPB-QKTWZHF-7MKLPBI-M6E6AQE";
        };
        "vps" = {
          id = "EPFW7TB-MUV25YB-P2SM66L-ENLRREJ-UJIRELD-QC2FWM4-RVSLFJY-7YWXCQ6";
          addresses = ["quic://firecat53.com:22000" "tcp://firecat53.com:22000"];
        };
        "scott-laptop" = {
          id = "ERJHQAD-KWQH5ZJ-CAV3ZFL-IR6ECOQ-EHVL7GY-6MY5A5M-IORUVXI-NSBYOQE";
        };
        "scott-office" = {
          id = "JJEHDJM-7EXVS6I-U5LIV3G-QH56XUA-77WXQZA-PXI4GIF-6ATNTOZ-5JA2FQV";
        };
        "chrystie-cell" = {
          id = "FIQHWMF-VUVWCGQ-BPUNYV5-5COXF36-OB6D52M-FSKLCYX-MWS7RWZ-KWQ56QK";
        };
        "chrystie-laptop" = {
          id = "OK2Y6E5-MITMIEJ-YHQHSZ2-VKJV2MA-GZUIAUD-UT2MW2T-QCQ4J6W-AAGILQN";
        };
      };
      folders = {
        "blackhole" = {
          path = "/mnt/downloads/blackhole";
          devices = ["chrystie-laptop"];
          id = "lduvp-dcpju";
        };
        "camera-chrystie" = {
          path = "/mnt/media/cameras/chrystie";
          devices = ["chrystie-laptop" "chrystie-cell"];
          id = "camera";
        };
        "camera-scotty" = {
          path = "/mnt/media/cameras/scotty";
          devices = ["scott-laptop" "scott-cell" "scott-office"];
          id = "camera-scotty";
        };
        "docs-scotty" = {
          path = "/home/firecat53/docs";
          devices = ["scott-laptop" "scott-cell" "scott-office"];
          id = "docs";
        };
        "docs-chrystie" = {
          path = "/home/chryspie/Christina-docs";
          devices = ["chrystie-laptop"];
          id = "wxbmh-jtaq9";
        };
        "file_xfer" = {
          path = "/home/firecat53/.local/tmp/file_xfer";
          devices = ["scott-cell" "scott-laptop" "scott-office"];
          id = "file_xfer";
        };
        "mail" = {
          path = "/home/firecat53/mail";
          devices = ["scott-laptop" "scott-office"];
          id = "sdgpi-zh6rd";
        };
        "mom_books" = {
          path = "/home/firecat53/.local/tmp/mom_books";
          devices = ["scott-laptop" "scott-office"];
          id = "quhfj-7uvtc";
        };
        "nixos" = {
          path = "/home/firecat53/nixos";
          devices = ["scott-laptop" "scott-office" "backup" "vps"];
          id = "smqlq-yhrua";
          type = "receiveonly";
        };
        "pictures-chrystie" = {
          path = "/home/chryspie/pictures";
          devices = ["chrystie-laptop"];
          id = "efadj-qkslz";
        };
        "shared" = {
          path = "/home/firecat53/shared";
          devices = ["scott-cell" "vps" "scott-laptop" "chrystie-laptop" "chrystie-cell" "scott-office"];
          id = "shared";
        };
        "srv" = {
          path = "/srv";
          devices = ["vps" "scott-laptop" "scott-office"];
          id = "srv";
        };
        "wallpaper" = {
          path = "/mnt/media/wallpaper";
          devices = ["scott-laptop" "scott-office"];
          id = "wallpaper";
        };
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.syncthing = {
    rule = "Host(`syncthing.lan.firecat53.net`)";
    service = "syncthing";
    middlewares = ["auth" "headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.syncthing = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8384";
        }
      ];
    };
  };
}
