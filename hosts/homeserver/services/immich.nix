# Immich
{
  services.immich = {
    accelerationDevices = null; # Access all devices
    enable = true;
    group = "users";
    machine-learning.enable = true;
    mediaLocation = "/mnt/media/immich";
    settings = null;
    user = "immich";
  };
  services.immich-public-proxy = {
    enable = true;
    port = 3030;
    immichUrl = "http://localhost:2283";
    settings = {
      "lightGallery" = {
        "controls" = true;
        "download" = true;
        "mobileSettings" = {
          "controls" = false;
          "showCloseIcon" = true;
          "download" = true;
        };
      };
    };
  };

  # Allow hardware transcoding
  users.users.immich.extraGroups = [ "render" ];

  services.traefik.dynamicConfigOptions.http.routers.immich = {
    rule = "Host(`pics.lan.firecat53.net`)";
    service = "immich";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.immich = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:2283";
        }
      ];
    };
  };

  # Immich Public Proxy (public sharing) - exposed at pix.firecat53.me via the VPS
  services.traefik.dynamicConfigOptions.http.routers.immich-public = {
    rule = "Host(`pix.lan.firecat53.net`)";
    service = "immich-public";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.immich-public = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3030";
        }
      ];
    };
  };
}
