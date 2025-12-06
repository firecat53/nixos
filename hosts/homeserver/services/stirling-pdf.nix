### Stirling-PDF https://github.com/Stirling-Tools/Stirling-PDF
{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 8880;
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.stirling-pdf = {
    rule = "Host(`pdf.lan.firecat53.net`)";
    service = "stirling-pdf";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.stirling-pdf = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8880";
        }
      ];
    };
  };
}
