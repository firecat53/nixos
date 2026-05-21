# Grafana
{ pkgs, ... }:
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
    provision = {
      enable = true;
      datasources.settings = {
        deleteDatasources = [
          {
            name = "Prometheus";
            orgId = 1;
          }
        ];
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            uid = "prometheus";
            isDefault = true;
            jsonData.timeInterval = "1m";
          }
        ];
      };
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = pkgs.runCommand "grafana-dashboards" { } ''
            mkdir -p $out
            cp ${./grafana-dashboards/server-overview.json} $out/server-overview.json
          '';
        }
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.grafana = {
    rule = "Host(`grafana.firecat53.com`)";
    service = "grafana";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
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
