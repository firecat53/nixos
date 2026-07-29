### Qbittorrent + wireguard + socks-proxy
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshKeys = import ../../modules/common/ssh-keys.nix;
  # Downloads land in /mnt/downloads, which permissions.nix creates as
  # 2775 firecat53:users — so qbittorrent runs as that uid:gid rather than
  # firecat53's own primary group. Baked into the image too, hence the plumbing.
  uid = config.users.users.firecat53.uid;
  gid = config.users.groups.users.gid;
  images = import ./images { inherit pkgs uid gid; };
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
    user = "${toString uid}:${toString gid}";
    dependsOn = [ "wireguard-client" ];
    environment = {
      QBT_WEBUI_PORT = "8081";
    };
    extraOptions = [
      "--cap-drop=all" # runs unprivileged; needs nothing back
      "--init=true"
      "--network=container:wireguard-client"
      "--pod=wg"
      "--security-opt=no-new-privileges"
    ];
    volumes = [
      "qbittorrent_config:/config"
      "/mnt/downloads:/data"
    ];
  };
  # Traefik routers/service generated from the registry (qbt entry) by lan-proxy.nix.

  # No firewall opening: the tunnel is entered via the host's sshd on 22 and
  # hops to 127.0.0.1:2222, and the gatus check arrives on wg0 (a trusted
  # interface). Nothing needs 2222 from the LAN.
  virtualisation.oci-containers.containers.socks-proxy = {
    image = ref images.socks-proxy;
    autoStart = true;
    dependsOn = [ "wireguard-client" ];
    # Keeps the generated host keys across image rebuilds.
    volumes = [ "socks_proxy_keys:/var/lib/socks-proxy" ];
    # sshd needs these four: bind 22, and drop to the privsep user in a chroot.
    extraOptions = [
      "--cap-drop=all"
      "--cap-add=NET_BIND_SERVICE"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
      "--cap-add=SYS_CHROOT"
      "--network=container:wireguard-client"
      "--pod=wg"
      "--security-opt=no-new-privileges"
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
      "--cap-drop=all"
      "--cap-add=NET_ADMIN" # wg-quick: interface, policy routing, its own rules
      "--cap-add=NET_RAW" # the config's PostUp ping
      "--dns=172.16.0.1"
      "--pod=wg"
    ];
  };
  # For wireguard-client
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
}
