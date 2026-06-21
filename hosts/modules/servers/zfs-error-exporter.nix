# ZFS per-vdev error exporter (node-exporter textfile metric).
#
# The zfs_exporter (services.prometheus.exporters.zfs) exposes pool health and
# capacity but NOT read/write/checksum/scan error counts. ZFS maintains the
# per-vdev read/write/checksum counters continuously during normal I/O (not just
# during scrubs) and latches them until `zpool clear`, so a degraded disk can
# accumulate checksum errors while the pool still reports ONLINE. We parse
# `zpool status -j` (OpenZFS 2.3+) and write the error counters as a textfile
# metric. Prometheus already scrapes node-exporter on every server, and the
# alert rules (ZFSPoolDeviceErrors / ZFSErrorExporterStale) live in
# hosts/vps/services/prometheus.nix.
{
  pkgs,
  ...
}:
let
  textfileDir = "/var/lib/prometheus-node-exporter-text";
  errorExporter = pkgs.writeShellScript "zfs-error-exporter" ''
    set -euo pipefail
    out="${textfileDir}/zfs_errors.prom"
    tmp="$(${pkgs.coreutils}/bin/mktemp "${textfileDir}/zfs_errors.prom.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

    {
      echo "# HELP zfs_pool_read_errors Read errors on the pool's top-level vdev."
      echo "# TYPE zfs_pool_read_errors gauge"
      echo "# HELP zfs_pool_write_errors Write errors on the pool's top-level vdev."
      echo "# TYPE zfs_pool_write_errors gauge"
      echo "# HELP zfs_pool_checksum_errors Checksum errors on the pool's top-level vdev."
      echo "# TYPE zfs_pool_checksum_errors gauge"
      echo "# HELP zfs_pool_scan_errors Errors reported by the last scrub/resilver."
      echo "# TYPE zfs_pool_scan_errors gauge"
      { ${pkgs.zfs}/bin/zpool status -j 2>/dev/null || echo '{}'; } | ${pkgs.jq}/bin/jq -r '
        (.pools // {}) | to_entries[] | .key as $p | .value |
        "zfs_pool_read_errors{pool=\"\($p)\"} \(.vdevs[$p].read_errors // "0")",
        "zfs_pool_write_errors{pool=\"\($p)\"} \(.vdevs[$p].write_errors // "0")",
        "zfs_pool_checksum_errors{pool=\"\($p)\"} \(.vdevs[$p].checksum_errors // "0")",
        "zfs_pool_scan_errors{pool=\"\($p)\"} \(.scan_stats.errors // "0")"
      '
    } > "$tmp"

    ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
    ${pkgs.coreutils}/bin/mv "$tmp" "$out"  # atomic: node-exporter never sees a partial file
    trap - EXIT
  '';
in
{
  systemd.services.zfs-error-exporter = {
    description = "Export ZFS per-pool error counts as a Prometheus textfile metric";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = errorExporter;
    };
  };

  systemd.timers.zfs-error-exporter = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3m";
      OnUnitActiveSec = "30m";
      Unit = "zfs-error-exporter.service";
    };
  };
}
