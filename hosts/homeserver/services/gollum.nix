# Gollum
{
  config,
  ...
}:
{
  services.gollum = {
    enable = true;
    user = "firecat53";
    group = "users";
    stateDir = "/home/firecat53/docs/family/scott/wiki";
    emoji = true;
    branch = "main";
    allowUploads = "page";
    address = "127.0.0.1";
  };
  # These next four lines are to work around a bug in the gollum module when a user other than `gollum` is assigned
  users.groups = {
    gollum = { };
  };
  users.users.gollum.isSystemUser = true;
  users.users.gollum.group = "gollum";
  systemd.tmpfiles.rules = [
    "d '${config.services.gollum.stateDir}' - ${config.users.users.firecat53.name} ${config.users.groups.users.name} - -"
  ];
  services.traefik.dynamicConfigOptions.http.routers.gollum = {
    rule = "Host(`gollum.lan.firecat53.net`)";
    service = "gollum";
    middlewares = [
      "auth"
      "headers"
    ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  # Requests proxied in from the VPS (10.200.200.5, i.e. gollum.firecat53.me)
  # are already 2FA'd by Authelia, so skip the native basicAuth. LAN/wireguard
  # clients hit the router above and still get basicAuth.
  services.traefik.dynamicConfigOptions.http.routers.gollum-noauth = {
    rule = "Host(`gollum.lan.firecat53.net`) && ClientIP(`10.200.200.5`)";
    service = "gollum";
    priority = 100;
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.gollum = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:4567";
        }
      ];
    };
  };
}
