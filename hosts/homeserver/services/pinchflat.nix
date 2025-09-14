# Pinchflat
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.pinchflat-env = { };
  services.pinchflat = {
    package = pkgs.pinchflat;
    enable = true;
    #group = "users";
    mediaDir = "/mnt/media/youtube";
    secretsFile = "${config.sops.secrets.pinchflat-env.path}";
    #user = "firecat53";
  };
  # Run as firecat53:users and disable DynamicUser (TODO - this should be part
  # of the module options already (2025/09/14) but it doesn't seem to be
  # working)
  systemd.services.pinchflat.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "firecat53";
    Group = lib.mkForce "users";
  };
  services.traefik.dynamicConfigOptions.http.routers.pinchflat = {
    rule = "Host(`yt.lan.firecat53.net`)";
    service = "pinchflat";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.pinchflat = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8945";
        }
      ];
    };
  };
}
