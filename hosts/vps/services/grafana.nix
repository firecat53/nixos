# Grafana
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.firecat53.com";
      };
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.grafana = {
    rule = "Host(`grafana.firecat53.com`)";
    service = "grafana";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.grafana = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3000";
        }
      ];
    };
  };
}
