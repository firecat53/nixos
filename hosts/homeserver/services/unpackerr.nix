# Unpackerr: extracts the rar'd torrents that sonarr/radarr park in the queue as
# "Found archive file, might need to be extracted", then removes the extracted
# copies once the *arr has imported them. Seeding is unaffected — only new files
# are written beside the torrent's own, and delete_orig stays off by default.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  reg = (import ../../modules/service-registry.nix).homeserver;
  conf = "/run/unpackerr/unpackerr.conf";

  # The API keys already live in each app's config.xml. Reading them at start
  # avoids a second copy in sops that would silently go stale on a key reset.
  writeConf = pkgs.writeShellScript "unpackerr-conf" ''
    set -eu
    apikey() { ${lib.getExe pkgs.gnused} -n 's|.*<ApiKey>\([^<]*\)</ApiKey>.*|\1|p' "$1"; }
    umask 077
    cat > ${conf} <<EOF
    # Group-writable, to match the default ACLs permissions.nix sets on
    # /mnt/downloads. Upstream's 0644/0755 would drop the group write bit.
    file_mode = "0664"
    dir_mode = "0775"

    [[sonarr]]
    url = "http://127.0.0.1:${toString reg.sonarr.port}"
    api_key = "$(apikey ${config.services.sonarr.dataDir}/config.xml)"
    # Fallback for when the path the *arr reports isn't reachable here — the
    # queue quotes qbittorrent's container-side /data/... paths.
    paths = ["/mnt/downloads/torrents"]

    [[radarr]]
    url = "http://127.0.0.1:${toString reg.radarr.port}"
    api_key = "$(apikey ${config.services.radarr.dataDir}/config.xml)"
    paths = ["/mnt/downloads/torrents"]

    # Hand-added torrents, which no *arr knows about. Output lands in
    # extracted/, already a jellyfin library path, so the seeding folder is left
    # alone. delete_files/delete_orig both default off, so nothing is ever
    # removed from either side; delete_after (10m) only retires the item from
    # tracking. That is deliberate — no importer runs here to confirm the file
    # landed anywhere else first, so the cleanup stays manual.
    # The folder poller defaults to off outside docker, so this is fsnotify
    # only: pre-existing folders are never touched, only ones created from now on.
    [[folder]]
    path = "/mnt/downloads/torrents/movies"
    extract_path = "/mnt/downloads/extracted/movies"

    [[folder]]
    path = "/mnt/downloads/torrents/tv"
    extract_path = "/mnt/downloads/extracted/tv"
    EOF
  '';
in
{
  systemd.services.unpackerr = {
    description = "Unpackerr";
    wantedBy = [ "multi-user.target" ];
    after = [
      "sonarr.service"
      "radarr.service"
    ];
    # Same as sonarr/radarr: extraction targets are on datapool, so don't start
    # against an empty tree.
    unitConfig.RequiresMountsFor = "/mnt/downloads";
    serviceConfig = {
      # Runs as the *arr user so it can read their 0700 dataDirs and write
      # through the users-group ACLs on /mnt/downloads.
      User = "firecat53";
      Group = "users";
      ExecStartPre = writeConf;
      ExecStart = "${lib.getExe pkgs.unpackerr} --config ${conf}";
      Restart = "on-failure";
      RuntimeDirectory = "unpackerr";

      # Sandbox. Archives arrive from public trackers, but the decoders are pure
      # Go (rardecode/sevenzip) with no helper binaries to reach for, so nothing
      # outside /mnt/downloads and the two localhost APIs is needed.
      AmbientCapabilities = "";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
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
      ReadWritePaths = [ "/mnt/downloads" ];
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
      SystemCallFilter = [
        "@system-service"
        "~@mount"
        "~@cpu-emulation"
      ];
      # No UMask: /mnt/downloads is group-shared through the default ACLs in
      # permissions.nix, and 0027 would strip the group write bit.
    };
  };
}
