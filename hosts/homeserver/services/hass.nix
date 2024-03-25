# Home Assistant - VM behind Traefik
{
  services.traefik.dynamicConfigOptions.http.routers.hass = {
    rule = "Host(`hass.lan.firecat53.net`)";
    service = "hass";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.hass = {
    loadBalancer = {
      servers = [
        {
          url = "http://192.168.200.102:8123";
        }
      ];
    };
  };
}
