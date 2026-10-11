# Read-only access to the family Macs' Kopia repos, plus a staleness metric.
#
# Each client's Mac backs up over SFTP into /home/<client>/backups. On this
# host, `kopia-<client>` is kopia with that repo's password (sops) and a static
# read-only config (Nix store) already set, so there's no connect step and no
# state in /root:
#
#   sudo kopia-jamia snapshot list --all -n1
#   sudo kopia-jamia mount all /mnt --fuse-allow-other
#
# Read-only keeps root from writing root-owned blobs into a repo the client's
# SFTP user must be able to rewrite during maintenance.
#
# A 6h timer writes the newest snapshot time per client as a node-exporter
# textfile metric; the KopiaBackupStale/KopiaCheckFailed/KopiaCheckStale
# alert rules live in hosts/vps/services/prometheus.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  clients = [
    "jamia"
    "janet"
  ];
  textfileDir = "/var/lib/prometheus-node-exporter-text";

  repoConfig =
    client:
    pkgs.writeText "kopia-${client}.config" (
      builtins.toJSON {
        storage = {
          type = "filesystem";
          config.path = "/home/${client}/backups";
        };
        # kopia panics on read if the cache sizes are missing
        caching = {
          cacheDirectory = "/var/cache/kopia/${client}";
          maxCacheSize = 500 * 1024 * 1024;
          maxMetadataCacheSize = 500 * 1024 * 1024;
        };
        readonly = true;
      }
    );

  wrapper =
    client:
    pkgs.writeShellApplication {
      name = "kopia-${client}";
      runtimeInputs = [ pkgs.kopia ];
      text = ''
        KOPIA_PASSWORD="$(< ${config.sops.secrets."kopia/${client}".path})"
        export KOPIA_PASSWORD
        export KOPIA_CONFIG_PATH=${repoConfig client}
        export KOPIA_CHECK_FOR_UPDATES=false
        exec kopia "$@"
      '';
    };
  wrappers = lib.genAttrs clients wrapper;

  exporter = pkgs.writeShellApplication {
    name = "kopia-snapshot-exporter";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      out="${textfileDir}/kopia.prom"
      tmp="$(mktemp "${textfileDir}/kopia.prom.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      {
        echo "# HELP kopia_snapshot_last_end_timestamp_seconds End time of the newest snapshot in the client's repo."
        echo "# TYPE kopia_snapshot_last_end_timestamp_seconds gauge"
        echo "# HELP kopia_check_success Whether the repo could be opened and had at least one snapshot."
        echo "# TYPE kopia_check_success gauge"
        ${lib.concatMapStrings (client: ''
          # jq -e fails on an empty repo (max of [] is null)
          if ts="$(${lib.getExe wrappers.${client}} snapshot list --all -n1 --json --disable-file-logging \
              | jq -e 'map(.endTime | sub("\\.[0-9]+"; "") | fromdateiso8601) | max')"; then
            echo "kopia_snapshot_last_end_timestamp_seconds{client=\"${client}\"} $ts"
            echo "kopia_check_success{client=\"${client}\"} 1"
          else
            echo "kopia_check_success{client=\"${client}\"} 0"
          fi
        '') clients}
      } > "$tmp"

      chmod 0644 "$tmp"
      mv "$tmp" "$out"  # atomic: node-exporter never sees a partial file
      trap - EXIT
    '';
  };
in
{
  sops.secrets = lib.genAttrs (map (client: "kopia/${client}") clients) (_: { });

  environment.systemPackages = builtins.attrValues wrappers;

  systemd.services.kopia-snapshot-exporter = {
    description = "Export newest Kopia snapshot time per client as a Prometheus textfile metric";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe exporter;
      CacheDirectory = "kopia";
    };
  };

  systemd.timers.kopia-snapshot-exporter = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "6h";
      Unit = "kopia-snapshot-exporter.service";
    };
  };
}
