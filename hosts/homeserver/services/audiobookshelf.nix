# Audiobookshelf
{
  pkgs,
  ...
}:
{
  services.audiobookshelf = {
    package = pkgs.audiobookshelf;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "audiobookshelf";
  };
  # The library folders span three mounts, and a rebuild that cycles datapool
  # (zfs-import-datapool -> mnt-downloads.mount) yanks them out from under a
  # running scanner, which then marks every item it can no longer see as
  # missing. Ordering on the mounts makes systemd stop and restart the service
  # with them instead of letting it run across the gap.
  systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = [
    "/mnt/media/audiobooks"
    "/mnt/media/ebooks"
    "/mnt/downloads"
  ];
  # Publicly exposed with no forward-auth (the mobile apps need the API
  # directly), so the unit gets the full sandbox. It only *reads* the libraries:
  # storeCoverWithItem/storeMetadataWithItem are off and there are no podcast
  # libraries, so covers, metadata and backups all live in the StateDirectory.
  # Turning either setting on — or uploading/deleting items from the web UI —
  # needs ReadWritePaths for the library folders.
  systemd.services.audiobookshelf.serviceConfig = {
    AmbientCapabilities = "";
    CapabilityBoundingSet = "";
    LockPersonality = true;
    # No MemoryDenyWriteExecute: the V8 JIT needs writable+executable pages.
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
    # No ProcSubset="pid": node sizes its heap and cpu pool from
    # /proc/meminfo and /proc/cpuinfo.
    ProtectSystem = "strict";
    RemoveIPC = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK" # getifaddrs/DNS resolution in node
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
    UMask = "0027";
  };
  # Traefik routers/service generated from the registry (books entry) by lan-proxy.nix.
}
