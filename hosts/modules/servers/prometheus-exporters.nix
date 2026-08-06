### Prometheus
{
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      extraFlags = [
        "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text"
        # Drop podman's transient healthcheck units (<container-id>-<hex>.service
        # and its .timer). A failing check is podman's to act on via the
        # container's failing streak, but it leaves the unit failed until the
        # next tick, which reads as a crash. The container ID in the name also
        # churns a new time series on every restart. Repeats node_exporter's own
        # default exclusions, which this flag overrides rather than extends.
        "--collector.systemd.unit-exclude=.+\\.(automount|device|mount|scope|slice)|[0-9a-f]{64}-[0-9a-f]{16}\\.(service|timer)"
      ];
    };
    zfs.enable = true;
  };

  # Shared textfile directory for node-exporter custom metrics. Owned by
  # firecat53 (the homeserver user-services exporter writes here as that user);
  # root-owned writers (airvpn-port-check, zfs-error-exporter) can still write.
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-node-exporter-text 0755 firecat53 root -"
  ];
}
