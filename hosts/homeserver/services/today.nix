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
  # today builds links to the matching gollum host from the request Host header,
  # so (like gollum) it can't use the .lan-name + ClientIP trick — it needs the
  # real host. The VPS passes it through (registry passHost = true), so remote
  # requests arrive here as today.firecat53.me, which only ever comes via the VPS
  # (already 2FA'd by Authelia), hence no basicAuth. LAN/wireguard clients use
  # today.lan.firecat53.net (the router above) and still get basicAuth.
  # No certResolver: the VPS->homeserver TLS uses SNI today.lan.firecat53.net,
  # whose cert the router above already provisions.
  services.traefik.dynamicConfigOptions.http.routers.today-me = {
    rule = "Host(`today.firecat53.me`)";
    service = "today";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = { };
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
