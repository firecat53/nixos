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
}
