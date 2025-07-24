{
  config,
  ...
}:
let
  domain = "firecat53.net";
  fqdn = "matrix.${domain}";
  baseUrl = "https://${fqdn}";
  clientConfig."m.homeserver".base_url = baseUrl;
  serverConfig."m.server" = "${fqdn}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  services.postgresql.enable = true;

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "${domain}" = {
        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      };
    };
  };

  sops.secrets.matrix-secret = {
    mode = "0440";
    owner = config.users.users.matrix-synapse.name;
    group = config.users.users.matrix-synapse.group;
  };
  services.matrix-synapse = {
    enable = true;
    extraConfigFiles = [
      "${config.sops.secrets.matrix-secret.path}"
    ];
    log.root.level = "WARNING";
    settings = {
      server_name = "${domain}";
      public_baseurl = baseUrl;
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.matrix = {
    rule = "Host(`${fqdn}`) && ((PathPrefix(`/_matrix`) || PathPrefix(`/_synapse/client`)))";
    service = "matrix";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.matrix = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8008";
        }
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.nginx-wellknown = {
    rule = "Host(`${fqdn}`) && PathPrefix(`/.well-known/matrix/`)";
    service = "nginx-wellknown";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.nginx-wellknown = {
    loadBalancer = {
      servers = [
        {
          # Redirect to nginx
          url = "http://localhost:${builtins.toString config.services.nginx.defaultHTTPListenPort}";
        }
      ];
    };
  };
}
