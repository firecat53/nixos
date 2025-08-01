# Open-WebUI
{
  pkgs,
  ...
}:
{
  services.open-webui = {
    package = pkgs.open-webui;
    enable = true;
    port = 8083;
  };
  services.traefik.dynamicConfigOptions.http.routers.openwebui = {
    rule = "Host(`ai.lan.firecat53.net`)";
    service = "openwebui";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.openwebui = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8083";
        }
      ];
    };
  };
}
