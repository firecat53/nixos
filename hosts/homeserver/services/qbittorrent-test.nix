### TEMPORARY: parallel copy of the wireguard pod on the dockerTools images.
#
# Runs beside the production stack in qbittorrent.nix, which stays on the
# ansible-built images until this proves out. Everything is separate: its own
# pod, ports, volumes, download directory and wireguard config, so nothing here
# touches production data.
#
# At cutover: delete this file and its import, point qbittorrent.nix at
# `images`, then remove the qbt-test registry entry, the wireguard-test-conf
# secret, and the leftover volumes and /mnt/downloads/qbt-test.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # -test names the images apart from production's, so loading and pruning here
  # can't disturb the `localhost/qbittorrent:latest` etc. the live stack runs.
  images = import ./images {
    inherit pkgs;
    suffix = "-test";
  };
  ref = image: "${image.imageName}:${image.imageTag}";
  loadImage = import ./images/load.nix { inherit pkgs; };
in
{
  # Same stale-lockfile workaround as production; see qbittorrent.nix.
  systemd.services.podman-qbittorrent-test.serviceConfig.ExecStartPre = lib.mkBefore [
    "${pkgs.coreutils}/bin/rm -f /var/lib/containers/storage/volumes/qbittorrent_test_config/_data/qBittorrent/lockfile"
    "${loadImage images.qbittorrent}"
  ];
  systemd.services.podman-socks-proxy-test.serviceConfig.ExecStartPre = lib.mkBefore [
    "${loadImage images.socks-proxy}"
  ];
  systemd.services.podman-wireguard-client-test.serviceConfig.ExecStartPre = lib.mkBefore [
    "${loadImage images.wireguard-client}"
  ];

  systemd.services.pod-wireguard-test = {
    description = "Start podman 'wg-test' pod";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    requiredBy = [
      "podman-wireguard-client-test.service"
      "podman-qbittorrent-test.service"
      "podman-socks-proxy-test.service"
    ];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 127.0.0.1:8092:8092 -p 2223:22 wg-test";
    };
    path = [
      pkgs.zfs
      pkgs.podman
    ];
  };

  # Fresh download directory, not the production /mnt/downloads.
  systemd.tmpfiles.rules = [
    "d /mnt/downloads/qbt-test 0775 firecat53 users -"
  ];

  virtualisation.oci-containers.containers.qbittorrent-test = {
    image = ref images.qbittorrent;
    autoStart = true;
    user = "1000:100";
    dependsOn = [ "wireguard-client-test" ];
    environment = {
      QBT_WEBUI_PORT = "8092";
    };
    extraOptions = [
      "--init=true"
      "--network=container:wireguard-client-test"
      "--pod=wg-test"
    ];
    volumes = [
      "qbittorrent_test_config:/config"
      "/mnt/downloads/qbt-test:/data"
    ];
  };
  # Traefik router/service generated from the registry (qbt-test entry).

  networking.firewall.allowedTCPPorts = [ 2223 ];
  virtualisation.oci-containers.containers.socks-proxy-test = {
    image = ref images.socks-proxy;
    autoStart = true;
    dependsOn = [ "wireguard-client-test" ];
    volumes = [ "socks_proxy_test_keys:/var/lib/socks-proxy" ];
    extraOptions = [
      "--pod=wg-test"
      "--network=container:wireguard-client-test"
    ];
  };

  # Separate tunnel from production's, so both can be up at once.
  sops.secrets.wireguard-test-conf = { };
  virtualisation.oci-containers.containers.wireguard-client-test = {
    image = ref images.wireguard-client;
    autoStart = true;
    volumes = [
      "${config.sops.secrets.wireguard-test-conf.path}:/etc/wireguard/wireguard0.conf:ro"
    ];
    environment = {
      LOCAL_NETWORKS = "10.200.200.0/24,192.168.200.0/24";
    };
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--dns=172.16.0.1"
      "--pod=wg-test"
    ];
  };
  # net.ipv4.conf.all.src_valid_mark is already set for production in
  # qbittorrent.nix and applies to this pod too.
}
