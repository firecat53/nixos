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

  # Traefik routers/services generated from the registry by lan-proxy.nix:
  # pics (immich) and pix (immich-public-proxy, public sharing).
}
