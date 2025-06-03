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
}
