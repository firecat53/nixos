# Prometheus and alertmanager
{
  config,
  sops,
  ...
}:{
  ## Prometheus 
  services.prometheus = {
    enable = true;
    extraFlags = [
      "--storage.tsdb.retention.time=30d"
    ];
    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            "10.200.200.4:9100"
            "10.200.200.6:9100"
          ];
        }];
      }
      {
        job_name = "zfs-exporter";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}"
            "10.200.200.4:9134"
            "10.200.200.6:9134"
          ];
        }];
      }
      {
        job_name = "podman-exporter";
        static_configs = [{
          targets = [
            "10.200.200.6:9882"
          ];
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.port}"
          ];
        }];
      }
    ];
    rules = [
      "groups:"
      "- name: targets"
      "  rules:"
      "    - alert: PrometheusTargetMissing"
      "      expr: up == 0"
      "      for: 30s"
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
      "  - alert: HostOutOfMemory"
      "    expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 5"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host out of memory (instance {{ $labels.instance }})"
      "      description: 'Node memory is filling up (< 5% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: high_memory_load"
      "    expr: (sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) ) / sum(node_memory_MemTotal_bytes) * 100 > 90"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'Server memory is almost full'"
      "      description: 'Docker host memory usage is {{ humanize $value}}%. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}.'"
      "  - alert: HostOutOfDiskSpace"
      "    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host out of disk space (instance {{ $labels.instance }})"
      "      description: 'Disk is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      " "
      "  - alert: high_storage_load"
      "    expr: (node_filesystem_size_bytes{fstype=~'btrfs|ext4'} - node_filesystem_free_bytes{fstype=~'btrfs|ext4'}) / node_filesystem_size_bytes{fstype=~'btrfs|ext4'}  * 100 > 85"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'Server storage is almost full'"
      "      description: 'Docker host storage usage is {{ humanize $value}}%. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}.'"

      "  - alert: HostDiskWillFillIn24Hours"
      "    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) predict_linear(node_filesystem_avail_bytes{fstype!~'tmpfs'}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly == 0"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host disk will fill in 24 hours (instance {{ $labels.instance }})"
      "      description: 'Filesystem is predicted to run out of space within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
      "  - alert: HostOutOfInodes"
      "    expr: node_filesystem_files_free{mountpoint ='/rootfs'} / node_filesystem_files{mountpoint='/rootfs'} * 100 < 10 and ON (instance, device, mountpoint) node_filesystem_readonly{mountpoint='/rootfs'} == 0"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: Host out of inodes (instance {{ $labels.instance }})"
      "      description: 'Disk is almost running out of available inodes (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
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
      "  - alert: high_cpu_load"
      "    expr: node_load1 > 15"
      "    for: 5m"
      "    labels:"
      "      severity: warning"
      "    annotations:"
      "      summary: 'Server under high load'"
      "      description: 'Docker host is under high load, the avg load 1m is at {{ $value}}. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}.'"
      "  - alert: HostNodeOvertemperatureAlarm"
      "    expr: node_hwmon_temp_crit_alarm_celsius == 1"
      "    for: 1m"
      "    labels:"
      "      severity: critical"
      "    annotations:"
      "      summary: Host node overtemperature alarm (instance {{ $labels.instance }})"
      "      description: 'Physical node temperature alarm triggered\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}'"
    ];
    alertmanager = {
      enable = true;
      listenAddress = "localhost";
      webExternalUrl = "https://alerts.firecat53.com";
      extraFlags = ["--cluster.listen-address="];
      configuration = {
        route = {
          group_by = ["alertname"];
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
                auth_password_file = "${config.sops.secrets.email-password.path}";
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

  ## Traefik config
  services.traefik.dynamicConfigOptions.http.routers.prometheus = {
    rule = "Host(`prom.firecat53.com`)";
    service = "prometheus";
    middlewares = ["auth" "headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.prometheus = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:9090";
        }
      ];
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.alertmanager = {
    rule = "Host(`alerts.firecat53.com`)";
    service = "alertmanager";
    middlewares = ["auth" "headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.alertmanager = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:9093";
        }
      ];
    };
  };

  ## Exporters
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = ["zfs"];
  };
  services.prometheus.exporters.systemd.enable = true;
  services.prometheus.exporters.zfs.enable = true;
}
