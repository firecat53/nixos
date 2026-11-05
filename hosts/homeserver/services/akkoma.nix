# akkoma
{
  pkgs,
  ...
}:
{
  services.akkoma = {
    enable = true;
    package = pkgs.unstable.akkoma;
    config = {
      ":pleroma" = {
        ":instance" = {
          name = "firecat53 akkoma";
          email = "scott@firecat53.net";
          description = "Akkoma server";
          registrations_open = false;
          invites_enabled = false;
        };
        "Pleroma.Web.Endpoint" = {
          url.host = "s.firecat53.net";
          http.ip = "127.0.0.1";
          http.port = 4000;
        };
        "Pleroma.Web.WebFinger" = {
          domain = "firecat53.net";
        };
        "Pleroma.Upload".base_url = "https://sm.firecat53.net/media";
        # Strips GPS, deduplicates and anonymizes filenames for uploaded files
        "Pleroma.Upload".filters = map (pkgs.formats.elixirConf { }).lib.mkRaw [
          "Pleroma.Upload.Filter.Exiftool.StripMetadata"
          "Pleroma.Upload.Filter.Dedupe"
          "Pleroma.Upload.Filter.AnonymizeFilename"
        ];
      };
    };
    # use default ffmpeg instead of the module default ffmpeg_5
    extraPackages = with pkgs; [
      exiftool
      ffmpeg-headless
      graphicsmagick-imagemagick-compat
    ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      akkoma = {
        rule = "Host(`s.firecat53.net`)";
        service = "akkoma";
        middlewares = [ "headers" ];
        entrypoints = [ "websecure" ];
        tls.certResolver = "le";
      };
      akkoma-media = {
        rule = "Host(`sm.firecat53.net`)";
        service = "akkoma";
        middlewares = [ "headers" ];
        entrypoints = [ "websecure" ];
        tls.certResolver = "le";
      };
    };
    services = {
      akkoma.loadBalancer.servers = [
        {
          url = "http://localhost:4000";
        }
      ];
    };
  };
}
