{
  services.uptime-kuma = {
    enable = true;
  };
  services.traefik.dynamicConfigOptions.http.routers.up = {
    rule = "Host(`up.lan.firecat53.net`)";
    service = "up";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.up = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3001";
        }
      ];
    };
  };
}
