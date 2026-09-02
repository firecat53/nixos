# Sabnzbd
{
  config,
  lib,
  ...
}:
{
  services.sabnzbd = {
    enable = true;
    configFile = null; # manage the ini through `settings` instead of the legacy file
    allowConfigWrite = true;
    user = "firecat53";
    group = "users";
    settings.misc.port = 8090;
  };
  # ReadWritePaths binds whatever is at /mnt/downloads when the unit starts, so
  # order after the mount rather than silently writing to the root pool.
  systemd.services.sabnzbd.unitConfig.RequiresMountsFor = "/mnt/downloads";
  systemd.services.sabnzbd.serviceConfig = {
    # Upstream daemonizes with -d; run in the foreground so logs reach the journal.
    Type = lib.mkForce "simple";
    ExecStart = lib.mkForce "${lib.getExe config.services.sabnzbd.package} -f /var/lib/${config.services.sabnzbd.stateDir}/sabnzbd.ini";
    StateDirectoryMode = "0700";

    # Sandbox. The web UI is protected but the real exposure is the content
    # path: sabnzbd hands Usenet payloads to unrar/par2/7z/unzip, which never
    # touch Authelia. Wrapper PATH is all store paths, so a read-only root is
    # enough for the helpers.
    AmbientCapabilities = "";
    CapabilityBoundingSet = "";
    LockPersonality = true;
    # No MemoryDenyWriteExecute: libffi/ctypes closures in the python stack.
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    # Whole tree r/w. Categories are added from the web UI, and a narrower list
    # could fail with new category folders.
    ReadWritePaths = [ "/mnt/downloads" ];
    RemoveIPC = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK" # getaddrinfo/getifaddrs
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
    # No UMask: completed downloads are group-shared through the default ACLs
    # in permissions.nix, and 0027 would strip the group write bit.
  };
  # nixpkgs' launcher forks python instead of exec'ing it, so the unit's MainPID
  # is a leftover bash parent. systemd then SIGTERMs bash *and* python, and the
  # second signal re-enters sabnzbd's shutdown handler and deadlocks it until the
  # 90s stop timeout SIGKILLs the lot. exec'ing leaves a single process, which
  # shuts down in ~0.4s. --replace-fail so this breaks loudly once nixpkgs fixes it.
  nixpkgs.overlays = [
    (final: prev: {
      sabnzbd = prev.sabnzbd.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/bin/.sabnzbd-wrapped \
            --replace-fail ' $*' ' "$@"'
          sed -i '1s|^|exec |' $out/bin/.sabnzbd-wrapped
        '';
      });
    })
  ];
  # Traefik routers/service generated from the registry (sabnzbd entry) by lan-proxy.nix.
}
