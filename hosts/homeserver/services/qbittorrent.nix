### Qbittorrent + wireguard + socks-proxy
{
  pkgs,
  ...
}:{
  systemd.services.pod-wireguard = {
    description = "Start podman 'wg' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-wireguard-client.service" "podman-qbitorrent.service" "podman-socks-proxy.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 8081:8081 -p 2222:22 wg";
    };
    path = [pkgs.zfs pkgs.podman];
  };
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "qbittorrent";
    autoStart = true;
    user = "1000:100";
    dependsOn = ["wireguard-client"];
    environment = {
      QBT_WEBUI_PORT = "8081";
    };
    extraOptions = [
      "--init=true"
      "--network=container:wireguard-client"
      "--pod=wg"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.qbittorrent.rule=Host(`qbt.lan.firecat53.net`)"
      "--label=traefik.http.routers.qbittorrent.entrypoints=websecure"
      "--label=traefik.http.routers.qbittorrent.tls.certResolver=le"
      "--label=traefik.http.routers.qbittorrent.middlewares=headers@file"
      "--label=traefik.http.services.qbittorrent.loadbalancer.server.port=8081"
    ];
    volumes = ["qbittorrent_config:/config" "/mnt/downloads:/data"];
  };
  # Firewall opening for the socks-proxy
  networking.firewall.allowedTCPPorts = [2222];
  virtualisation.oci-containers.containers.socks-proxy = {
    image = "socks-proxy";
    autoStart = true;
    dependsOn = ["wireguard-client"];
    extraOptions = [
      "--pod=wg"
      "--network=container:wireguard-client"
    ];
  };
  virtualisation.oci-containers.containers.wireguard-client = {
    image = "wireguard-client";
    autoStart = true;
    volumes = ["wireguard_config:/etc/wireguard"];
    environment = {
      LOCAL_NETWORKS = "10.200.200.0/24,192.168.200.0/24";
    };
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--dns=172.16.0.1"
      "--pod=wg"
    ];
  };
  # For wireguard-client
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # For monitoring the podman containers
  virtualisation.oci-containers.containers.podman-exporter = {
    image = "podman-exporter";
    autoStart = true;
    ports = ["9882:9882"];
    volumes = ["/run/podman/podman.sock:/run/podman/podman.sock"];
    environment = {
      CONTAINER_HOST = "unix:///run/podman/podman.sock";
    };
  };
}
