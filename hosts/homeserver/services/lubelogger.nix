### Lubelogger
{
  services.lubelogger = {
    enable = true;
  };

  services.traefik.dynamicConfigOptions.http.routers.lubelogger = {
    rule = "Host(`cars.lan.firecat53.net`)";
    service = "lubelogger";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.lubelogger = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:5000";
        }
      ];
    };
  };
}
