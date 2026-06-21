### Prometheus
{
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      extraFlags = [
        "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text"
      ];
    };
    systemd.enable = true;
    zfs.enable = true;
  };

  # Shared textfile directory for node-exporter custom metrics. Owned by
  # firecat53 (the homeserver user-services exporter writes here as that user);
  # root-owned writers (airvpn-port-check, zfs-error-exporter) can still write.
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-node-exporter-text 0755 firecat53 root -"
  ];
}
