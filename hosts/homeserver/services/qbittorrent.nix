### Qbittorrent + wireguard + socks-proxy
{
  lib,
  pkgs,
  ...
}:
let
  sshKeys = import ../../modules/common/ssh-keys.nix;
in
{
  # Recent qBittorrent versions use a PID-based QLockFile for single-instance
  # enforcement. PID namespacing makes its stale-lock detection unreliable across
  # container restarts, so an ungraceful kill leaves a "lockfile" behind that blocks
  # the next start. Remove it before each start so restarts always succeed.
  systemd.services.podman-qbittorrent.serviceConfig.ExecStartPre = lib.mkBefore [
    "${pkgs.coreutils}/bin/rm -f /var/lib/containers/storage/volumes/qbittorrent_config/_data/qBittorrent/lockfile"
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
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 8081:8081 -p 2222:22 wg";
    };
    path = [
      pkgs.zfs
      pkgs.podman
    ];
  };
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "qbittorrent";
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
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.qbittorrent.rule=Host(`qbt.lan.firecat53.net`)"
      "--label=traefik.http.routers.qbittorrent.entrypoints=websecure"
      "--label=traefik.http.routers.qbittorrent.tls.certResolver=le"
      "--label=traefik.http.routers.qbittorrent.middlewares=headers@file"
      "--label=traefik.http.services.qbittorrent.loadbalancer.server.port=8081"
    ];
    volumes = [
      "qbittorrent_config:/config"
      "/mnt/downloads:/data"
    ];
  };
  # Firewall opening for the socks-proxy
  networking.firewall.allowedTCPPorts = [ 2222 ];
  virtualisation.oci-containers.containers.socks-proxy = {
    image = "socks-proxy";
    autoStart = true;
    dependsOn = [ "wireguard-client" ];
    extraOptions = [
      "--pod=wg"
      "--network=container:wireguard-client"
    ];
  };
  virtualisation.oci-containers.containers.wireguard-client = {
    image = "wireguard-client";
    autoStart = true;
    volumes = [ "wireguard_config:/etc/wireguard" ];
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
