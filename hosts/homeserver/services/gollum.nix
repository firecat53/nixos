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
  # Sandbox. The wiki is a git repo in my home dir, so ProtectHome=tmpfs hides
  # every other home and BindPaths exposes just that one tree, read-write for
  # the commits. git comes from the unit's `path`, so a read-only store is
  # enough.
  systemd.services.gollum.serviceConfig = {
    AmbientCapabilities = "";
    BindPaths = [ config.services.gollum.stateDir ];
    CapabilityBoundingSet = "";
    LockPersonality = true;
    # No MemoryDenyWriteExecute: libffi/native gems in the ruby stack.
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = "tmpfs";
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RemoveIPC = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@mount"
      "~@cpu-emulation"
    ];
    # No UMask: the wiki lives under /home/firecat53/docs, which carries the
    # group-shared default ACLs from permissions.nix.
  };
  # Traefik routers/service (basicAuth + -me + -noauth companions) generated
  # from the registry (gollum entry) by lan-proxy.nix.
}
