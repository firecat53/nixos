# Grafana
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.grafana-secret-key = { };
  sops.secrets.grafana-oauth-secret.owner = "grafana";
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "grafana.firecat53.com";
        root_url = "https://grafana.firecat53.com/";
      };
      security.secret_key = "${config.sops.secrets.grafana-secret-key.path}";
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "grafana";
        client_secret = "$__file{${config.sops.secrets.grafana-oauth-secret.path}}";
        scopes = "openid profile email groups";
        auth_url = "https://auth.firecat53.me/api/oidc/authorization";
        token_url = "https://auth.firecat53.me/api/oidc/token";
        api_url = "https://auth.firecat53.me/api/oidc/userinfo";
        use_pkce = true;
        allow_sign_up = true;
        # Single-admin instance: anyone who passes Authelia 2FA is an Admin.
        # Refine with Authelia groups via role_attribute_path if needed.
        role_attribute_path = "'Admin'";
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
