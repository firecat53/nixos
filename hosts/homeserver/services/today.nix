# Today — quick diary/workout/book entry companion for my wiki
{
  pkgs,
  ...
}:
let
  localPkgs = import ../../../pkgs { inherit pkgs; };
in
{
  systemd.services.today = {
    description = "Today — quick wiki entry webapp";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "firecat53";
      Group = "users";
      ExecStart = "${localPkgs.today}/bin/today";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "WIKI_DIR=/home/firecat53/docs/family/scott/wiki"
        "PORT=4568"
        "PYTHONUNBUFFERED=1"
      ];
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.today = {
    rule = "Host(`today.lan.firecat53.net`)";
    service = "today";
    middlewares = [
      "auth"
      "headers"
    ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  # Requests proxied in from the VPS (10.200.200.5, i.e. today.firecat53.me)
  # are already 2FA'd by Authelia, so skip the native basicAuth. LAN/wireguard
  # clients hit the router above and still get basicAuth.
  services.traefik.dynamicConfigOptions.http.routers.today-noauth = {
    rule = "Host(`today.lan.firecat53.net`) && ClientIP(`10.200.200.5`)";
    service = "today";
    priority = 100;
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.today = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:4568";
        }
      ];
    };
  };
}
