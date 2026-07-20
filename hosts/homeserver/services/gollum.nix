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
  # Traefik routers/service (basicAuth + -me + -noauth companions) generated
  # from the registry (gollum entry) by lan-proxy.nix.
}
