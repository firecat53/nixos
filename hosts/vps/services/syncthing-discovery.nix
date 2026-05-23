# Syncthing global discovery server (stdiscosrv) behind Traefik
{
  pkgs,
  ...
}:
{
  users.users.stdiscosrv = {
    isSystemUser = true;
    group = "stdiscosrv";
    home = "/var/lib/syncthing-discovery";
    createHome = true;
  };
  users.groups.stdiscosrv = { };

  systemd.services.syncthing-discovery = {
    description = "Syncthing Discovery Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "stdiscosrv";
      Group = "stdiscosrv";
      ExecStart = "${pkgs.syncthing-discovery}/bin/stdiscosrv --http --listen 127.0.0.1:8443 --db-dir /var/lib/syncthing-discovery";
      Restart = "on-failure";
      RestartSec = 5;
      StateDirectory = "syncthing-discovery";
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.syncthing-discovery = {
    rule = "Host(`discover.firecat53.com`)";
    service = "syncthing-discovery";
    entrypoints = [ "websecure" ];
    middlewares = [ "syncthing-discovery-clientcert" ];
    tls = {
      certResolver = "le";
      options = "syncthing-discovery-mtls";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.syncthing-discovery = {
    loadBalancer = {
      servers = [
        {
          url = "http://127.0.0.1:8443";
        }
      ];
      passHostHeader = true;
    };
  };
  # Forward the client's TLS cert to stdiscosrv as X-SSL-Cert (PEM, URL-escaped).
  # stdiscosrv uses it to derive the announcing device's ID.
  services.traefik.dynamicConfigOptions.http.middlewares.syncthing-discovery-clientcert = {
    passTLSClientCert = {
      pem = true;
    };
  };
  # Request (but don't require) a client cert so syncthing can present its device cert.
  services.traefik.dynamicConfigOptions.tls.options.syncthing-discovery-mtls = {
    minVersion = "VersionTLS12";
    clientAuth = {
      clientAuthType = "RequestClientCert";
    };
  };
}
