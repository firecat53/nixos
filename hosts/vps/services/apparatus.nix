{
  pkgs,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d /opt/apparatus 0755 root root -"
  ];

  systemd.services.apparatus-git = {
    description = "Pull dashboard code";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /opt/apparatus && if [ -d .git ]; then ${pkgs.git}/bin/git pull; else ${pkgs.git}/bin/git clone https://github.com/firecat53/BFD-apparatus.git .; fi'";
    };
  };
  systemd.services.apparatus = {
    description = "BFD apparatus dashboard service";
    after = [
      "network.target"
      "apparatus-git.service"
    ];
    wants = [ "apparatus-git.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.pocketbase}/bin/pocketbase serve --dir /var/lib/apparatus --publicDir /opt/apparatus";
      WorkingDirectory = "/opt/apparatus";
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      DynamicUser = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      ReadOnlyPaths = "/opt/apparatus";
      ReadWritePaths = "/opt/apparatus/pb_migrations";
      RemoveIPC = true;
      Restart = "always";
      RestartSec = "10s";
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      StateDirectory = "apparatus";
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@mount"
        "~@cpu-emulation"
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.apparatus = {
    rule = "Host(`bfd.firecat53.com`)";
    service = "apparatus";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.apparatus = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8090";
        }
      ];
    };
  };
}
