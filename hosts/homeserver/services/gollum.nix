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
  # Gollum builds absolute redirects/URLs from the Host header, so unlike the
  # other basicAuth services it can't use the .lan-name + ClientIP trick. The VPS
  # passes the real host through (registry passHost = true), so requests arrive
  # here as gollum.firecat53.me — which only ever comes via the VPS (already
  # 2FA'd by Authelia), hence no basicAuth. LAN/wireguard clients use
  # gollum.lan.firecat53.net (the router above) and still get basicAuth.
  # No certResolver: the VPS->homeserver TLS uses SNI gollum.lan.firecat53.net,
  # whose cert the router above already provisions (firecat53.me certs live on
  # the VPS, which has the Porkbun DNS credentials — not here).
  services.traefik.dynamicConfigOptions.http.routers.gollum-me = {
    rule = "Host(`gollum.firecat53.me`)";
    service = "gollum";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = { };
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
