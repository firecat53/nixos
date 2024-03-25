### Prometheus
{
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = ["systemd"];
    };
    systemd.enable = true;
    zfs.enable = true;
  };
}
