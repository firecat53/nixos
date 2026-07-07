{
  config,
  inputs,
  pkgs,
  ...
}:
let
  crewsense = inputs.crewsense.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  systemd.tmpfiles.rules = [
    "d /opt/apparatus 0755 root root -"
  ];

  systemd.services.apparatus-git = {
    description = "Pull dashboard code";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /opt/apparatus && if [ -d .git ]; then ${pkgs.git}/bin/git pull; else ${pkgs.git}/bin/git clone https://git.firecat53.me/firecat53/BFD-apparatus.git .; fi'";
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
  sops.secrets.crewsense-client-id = { };
  sops.secrets.crewsense-client-secret = { };
  sops.templates."crewsense.env".content = ''
    CREWSENSE_CLIENT_ID=${config.sops.placeholder.crewsense-client-id}
    CREWSENSE_CLIENT_SECRET=${config.sops.placeholder.crewsense-client-secret}
  '';

  systemd.services.crewsense-report = {
    description = "Email daily BFD force-hold eligibility report";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    script = ''
      set -o pipefail
      report=$(${crewsense}/bin/crewsense report --mime bc@cob.org \
        --mail-from "Force Holds <scott@firecat53.net>")
      printf '%s\n' "$report" | ${pkgs.msmtp}/bin/msmtp -t
    '';
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      # A manual root `crewsense login` leaves cookies.txt owned by root;
      # re-own cache contents to the dynamic user before each run
      ExecStartPre = "+${pkgs.coreutils}/bin/chown -R --reference=/var/cache/private/crewsense /var/cache/private/crewsense";
      # Read access to the msmtp email-password secret
      SupplementaryGroups = [ "msmtp" ];
      EnvironmentFile = config.sops.templates."crewsense.env".path;
      # Persist the crewsense login cookie jar between runs
      CacheDirectory = "crewsense";
      Environment = "XDG_CACHE_HOME=/var/cache";
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      LockPersonality = true;
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
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
    };
  };
  systemd.timers.crewsense-report = {
    description = "Daily 1900 BFD force-hold eligibility report";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 19:00:00";
      Persistent = true;
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
