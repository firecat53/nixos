### Qbittorrent + wireguard + socks-proxy
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshKeys = import ../../modules/common/ssh-keys.nix;
  images = import ./images { inherit pkgs; };
  ref = image: "${image.imageName}:${image.imageTag}";
  loadImage = import ./images/load.nix { inherit pkgs; };
in
{
  # Recent qBittorrent versions use a PID-based QLockFile for single-instance
  # enforcement. PID namespacing makes its stale-lock detection unreliable across
  # container restarts, so an ungraceful kill leaves a "lockfile" behind that blocks
  # the next start. Remove it before each start so restarts always succeed.
  systemd.services.podman-qbittorrent.serviceConfig.ExecStartPre = lib.mkBefore [
    "${pkgs.coreutils}/bin/rm -f /var/lib/containers/storage/volumes/qbittorrent_config/_data/qBittorrent/lockfile"
    "${loadImage images.qbittorrent}"
  ];
  systemd.services.podman-socks-proxy.serviceConfig.ExecStartPre = lib.mkBefore [
    "${loadImage images.socks-proxy}"
  ];
  systemd.services.podman-wireguard-client.serviceConfig.ExecStartPre = lib.mkBefore [
    "${loadImage images.wireguard-client}"
  ];

  # Add autossh key for socks-proxy
  users.users.firecat53.openssh.authorizedKeys.keys = [
    sshKeys.autossh
  ];

  systemd.services.pod-wireguard = {
    description = "Start podman 'wg' pod";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    requiredBy = [
      "podman-wireguard-client.service"
      "podman-qbittorrent.service"
      "podman-socks-proxy.service"
    ];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 127.0.0.1:8081:8081 -p 2222:22 wg";
    };
    path = [
      pkgs.zfs
      pkgs.podman
    ];
  };
  virtualisation.oci-containers.containers.qbittorrent = {
    image = ref images.qbittorrent;
    autoStart = true;
    user = "1000:100";
    dependsOn = [ "wireguard-client" ];
    environment = {
      QBT_WEBUI_PORT = "8081";
    };
    extraOptions = [
      "--init=true"
      "--network=container:wireguard-client"
      "--pod=wg"
    ];
    volumes = [
      "qbittorrent_config:/config"
      "/mnt/downloads:/data"
    ];
  };
  # Traefik routers/service generated from the registry (qbt entry) by lan-proxy.nix.

  # Firewall opening for the socks-proxy
  networking.firewall.allowedTCPPorts = [ 2222 ];
  virtualisation.oci-containers.containers.socks-proxy = {
    image = ref images.socks-proxy;
    autoStart = true;
    dependsOn = [ "wireguard-client" ];
    # Keeps the generated host keys across image rebuilds.
    volumes = [ "socks_proxy_keys:/var/lib/socks-proxy" ];
    extraOptions = [
      "--pod=wg"
      "--network=container:wireguard-client"
    ];
  };
  sops.secrets.wireguard-conf = { };
  virtualisation.oci-containers.containers.wireguard-client = {
    image = ref images.wireguard-client;
    autoStart = true;
    volumes = [ "${config.sops.secrets.wireguard-conf.path}:/etc/wireguard/wireguard0.conf:ro" ];
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
}
