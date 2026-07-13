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
    group = "users";
    mediaDir = "/mnt/media/youtube";
    secretsFile = "${config.sops.secrets.pinchflat-env.path}";
    user = "firecat53";
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
