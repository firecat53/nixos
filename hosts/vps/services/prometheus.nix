# Prometheus and alertmanager
{
  config,
  ...
}:
{
  ## Prometheus
  services.prometheus = {
    enable = true;
    extraFlags = [
      "--storage.tsdb.retention.time=30d"
    ];
    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            labels.instance = "vps";
          }
          {
            targets = [ "10.200.200.4:9100" ];
            labels.instance = "backup";
          }
          {
            targets = [ "10.200.200.6:9100" ];
            labels.instance = "homeserver";
          }
        ];
      }
      {
        job_name = "zfs-exporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}" ];
            labels.instance = "vps";
          }
          {
            targets = [ "10.200.200.4:9134" ];
            labels.instance = "backup";
          }
          {
            targets = [ "10.200.200.6:9134" ];
            labels.instance = "homeserver";
          }
        ];
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
            labels.instance = "vps";
          }
        ];
      }
    ];
    rules = [
      "groups:"
      "- name: targets"
      "  rules:"
      "    - alert: PrometheusTargetMissing"
      "      expr: up == 0"
      "      for: 2m"
      "      labels:"
      "        severity: critical"
      "      annotations:"
      "        summary: Prometheus target missing (instance {{ $labels.instance }})"
      "        description: 'A Prometheus target has disappeared. An exporter might be crashed.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "- name: host"
      "  rules:"
      "  - alert: HostSystemdServiceCrashed"
      "    expr: node_systemd_unit_state{state='failed'} == 1"
      "    for: 1m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host systemd service crashed (instance {{ $labels.instance }})"
      "      description: 'systemd service crashed\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: UserSystemdServiceCrashed"
      "    expr: node_systemd_user_unit_state{state='failed'} == 1"
      "    for: 2m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: User systemd service crashed (instance {{ $labels.instance }})"
      "      description: 'User systemd service {{ $labels.name }} crashed for firecat53\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostOutOfMemory"
      "    expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 5"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host out of memory (instance {{ $labels.instance }})"
      "      description: 'Node memory is filling up (< 5% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostOutOfDiskSpace"
      "    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host out of disk space (instance {{ $labels.instance }})"
      "      description: 'Disk is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostDiskWillFillIn24Hours"
      "    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) predict_linear(node_filesystem_avail_bytes{fstype!~'tmpfs'}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly == 0"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host disk will fill in 24 hours (instance {{ $labels.instance }})"
      "      description: 'Filesystem is predicted to run out of space within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostUnusualDiskReadLatency"
      "    expr: rate(node_disk_read_time_seconds_total{device!~'dm-.*|sdf.*'}[1m]) / rate(node_disk_reads_completed_total{device!~'dm-.*|sdf.*'}[1m]) > 0.1 and rate(node_disk_reads_completed_total{device!~'dm-.*'}[1m]) > 0"
      "    # Exclude dm- (encrypted volumes) and sdf (external drive) from this tolerance as they are frequently slow"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host unusual disk read latency (instance {{ $labels.instance }})"
      "      description: 'Disk latency is growing (read operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostUnusualSlowDiskReadLatency"
      "    expr: rate(node_disk_read_time_seconds_total{device=~'dm-.*|sdf.*'}[1m]) / rate(node_disk_reads_completed_total{device=~'dm-.*|sdf.*'}[1m]) > 0.35 and rate(node_disk_reads_completed_total{device!~'dm-.*|sdf.*'}[1m]) > 350"
      "    # Include only dm- (encrypted volumes) and sdf (external drive) for this tolerance as they are frequently slow"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host unusual slow disk read latency (instance {{ $labels.instance }})"
      "      description: 'Disk latency is growing (read operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostUnusualDiskWriteLatency"
      "    expr: rate(node_disk_write_time_seconds_total{device!~'dm-.*|sdf.*'}[1m]) / rate(node_disk_writes_completed_total{device!~'dm-.*|sdf.*'}[1m]) > 0.1 and rate(node_disk_writes_completed_total{device!~'dm-.*|sdf.*'}[1m]) > 0"
      "    # Exclude dm- (encrypted volumes) and sdf (external drive) from this tolerance as they are frequently slow"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host unusual disk write latency (instance {{ $labels.instance }})"
      "      description: 'Disk latency is growing (write operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostUnusualSlowDiskWriteLatency"
      "    expr: rate(node_disk_write_time_seconds_total{device=~'dm-.*|sdf.*'}[1m]) / rate(node_disk_writes_completed_total{device=~'dm-.*|sdf.*'}[1m]) > 0.35 and rate(node_disk_writes_completed_total{device=~'dm-.*|sdf.*'}[1m]) > 350"
      "    # Include only dm- (encrypted volumes) and sdf (external drive) for this tolerance as they are frequently slow"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host unusual slow disk write latency (instance {{ $labels.instance }})"
      "      description: 'Disk latency is growing (write operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostHighCpuLoad"
      "    expr: node_load5 / count without (cpu, mode) (node_cpu_seconds_total{mode='idle'}) > 2"
      "    for: 10m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'Host under high load (instance {{ $labels.instance }})'"
      "      description: '5m load average is {{ humanize $value }}x the CPU core count on {{ $labels.instance }}.'"
      "  - alert: HostNodeOvertemperatureAlarm"
      "    expr: node_hwmon_temp_crit_alarm_celsius == 1"
      "    for: 1m"
      "    labels:"
      "      severity: critical"
      "    annotations:"
      "      summary: Host node overtemperature alarm (instance {{ $labels.instance }})"
      "      description: 'Physical node temperature alarm triggered\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      # ZFS: pool health/capacity come from the zfs_exporter (zfs_pool_*).
      # Per-vdev error counts come from the zfs-error-exporter textfile metrics
      # (zfs-error-exporter.nix) since the zfs_exporter does not expose them.
      "- name: zfs"
      "  rules:"
      "  - alert: ZFSPoolUnhealthy"
      "    expr: zfs_pool_health != 0"
      "    for: 1m"
      "    labels:"
      "      severity: critical"
      "    annotations:"
      "      summary: 'ZFS pool not healthy (instance {{ $labels.instance }}, pool {{ $labels.pool }})'"
      "      description: 'Pool {{ $labels.pool }} is not ONLINE (health code {{ $value }}: 1=DEGRADED 2=FAULTED 3=OFFLINE 4=UNAVAIL 5=REMOVED 6=SUSPENDED).'"
      "  - alert: ZFSPoolCapacityHigh"
      "    expr: zfs_pool_allocated_bytes / zfs_pool_size_bytes * 100 > 80"
      "    for: 10m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'ZFS pool over 80% full (instance {{ $labels.instance }}, pool {{ $labels.pool }})'"
      "      description: 'Pool {{ $labels.pool }} is {{ humanize $value }}% full. ZFS performance degrades sharply past ~80%.'"
      "  - alert: ZFSPoolDeviceErrors"
      "    expr: (zfs_pool_read_errors + zfs_pool_write_errors + zfs_pool_checksum_errors + zfs_pool_scan_errors) > 0"
      "    for: 1m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'ZFS pool device errors (instance {{ $labels.instance }}, pool {{ $labels.pool }})'"
      "      description: 'Pool {{ $labels.pool }} reports read/write/checksum/scan errors. Run zpool status; a disk may be failing.'"
      "  - alert: ZFSErrorExporterStale"
      "    expr: time() - node_textfile_mtime_seconds{file='zfs_errors.prom'} > 7200"
      "    for: 10m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'ZFS error exporter is stale (instance {{ $labels.instance }})'"
      "      description: 'zfs_errors.prom has not been updated in > 2h: the zfs-error-exporter timer is failing, so pool error metrics are not current.'"
      # AirVPN forwarded port: metric written by the airvpn-port-check timer
      # (see airvpn-port-check.nix). 'for: 16m' requires the port to be down
      # across two consecutive 15m checks before alerting (suppresses blips).
      "- name: airvpn"
      "  rules:"
      "  - alert: AirVPNForwardedPortDown"
      "    expr: airvpn_forwarded_port_up == 0"
      "    for: 16m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'AirVPN forwarded port 27430 unreachable'"
      "      description: 'The AirVPN forwarded port (27430) for qBittorrent is not reachable over TCP. Torrents may not be connectable/seeding.\n  VALUE = {{ $value }}'"
      "  - alert: AirVPNPortCheckStale"
      "    expr: time() - node_textfile_mtime_seconds{file='airvpn.prom'} > 1800"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'AirVPN port check is stale'"
      "      description: 'airvpn.prom has not been updated in > 30m: the airvpn-port-check timer or the AirVPN API is failing.\n  VALUE = {{ $value }}s'"
    ];
    alertmanager = {
      enable = true;
      listenAddress = "0.0.0.0";
      webExternalUrl = "https://alerts.firecat53.me";
      extraFlags = [ "--cluster.listen-address=" ];
      configuration = {
        route = {
          group_by = [ "alertname" ];
          repeat_interval = "24h";
          receiver = "default";
        };
        receivers = [
          {
            name = "default";
            email_configs = [
              {
                to = "tech@firecat53.net";
                smarthost = "smtp.fastmail.com:587";
                from = "noreply@firecat53.net";
                auth_username = "scott@firecat53.net";
                auth_password_file = "/run/credentials/alertmanager.service/email_pass";
              }
            ];
          }
        ];
      };
    };
    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
            ];
          }
        ];
      }
    ];
  };

  # Alertmanager override for systemd credentials
  systemd.services.alertmanager = {
    serviceConfig = {
      LoadCredential = [
        "email_pass:${config.sops.secrets.email-password.path}"
      ];
    };
  };

  # Public routers for prom/alerts are generated from registry.nix (local
  # entries, auth = true) by proxy-me.nix, which wires the Authelia forward-auth
  # middleware and the two_factor access_control rule. Served at
  # prom.firecat53.me / alerts.firecat53.me.

  ## Exporters
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "zfs" ];
  };
  services.prometheus.exporters.systemd.enable = true;
  services.prometheus.exporters.zfs.enable = true;
}
