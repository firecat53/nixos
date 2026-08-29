# Today — quick diary/workout/book entry companion for my wiki
{
  pkgs,
  ...
}:
let
  localPkgs = import ../../../pkgs { inherit pkgs; };
  wikiDir = "/home/firecat53/docs/family/scott/wiki";
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
        "WIKI_DIR=${wikiDir}"
        "PORT=4568"
        "PYTHONUNBUFFERED=1"
      ];

      # Sandbox. The app only ever touches WIKI_DIR, so ProtectHome=tmpfs hides
      # every other home and BindPaths exposes just that tree rw.
      AmbientCapabilities = "";
      BindPaths = [ wikiDir ];
      CapabilityBoundingSet = "";
      LockPersonality = true;
      # No MemoryDenyWriteExecute: libffi/ctypes closures in the python stack.
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
  };

  # Traefik routers/service (basicAuth + -me companion) generated from the
  # registry (today entry) by lan-proxy.nix.
}
