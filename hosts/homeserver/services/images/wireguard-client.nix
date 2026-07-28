# Wireguard client. Owns the pod's network namespace; qbittorrent and
# socks-proxy join it with --network=container:wireguard-client.
{ pkgs }:
let
  inherit (pkgs) lib;

  interface = "wireguard0";

  # wg-quick pipes the config's DNS= entries to resolvconf. openresolv expects a
  # resolvconf setup that doesn't exist here, so write the file directly.
  resolvconf = pkgs.writeShellScriptBin "resolvconf" ''
    [ "$1" = "-a" ] && cat > /etc/resolv.conf
    exit 0
  '';

  entrypoint = pkgs.writeShellScriptBin "wireguard-client" ''
    set -e
    # The shim has to precede openresolv, which wg-quick appends to PATH itself.
    export PATH=${
      lib.makeBinPath [
        resolvconf
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.iproute2
        pkgs.iputils # the config's PostUp pings the endpoint
        pkgs.wireguard-tools
      ]
    }

    if [ ! -e /etc/wireguard/${interface}.conf ]; then
        echo "No configuration file at /etc/wireguard/${interface}.conf" >&2
        exit 1
    fi

    # wg-quick sets this itself when it isn't already 1, which needs privileges
    # the container doesn't have. Set on the host in qbittorrent.nix instead.
    if [ "$(cat /proc/sys/net/ipv4/conf/all/src_valid_mark)" != "1" ]; then
        echo "sysctl net.ipv4.conf.all.src_valid_mark=1 is not set" >&2
        exit 1
    fi

    wg-quick up ${interface}

    # Keep the LAN reachable through the original gateway
    if [ -n "''${LOCAL_NETWORKS:-}" ]; then
        eval "$(ip r l | grep -v "${interface}\|kernel" | awk '{print "GW="$3"\nINT="$5}')"
        for network in ''${LOCAL_NETWORKS//,/ }; do
            ip route add "$network" via "$GW" dev "$INT"
        done
    fi

    shutdown () {
        wg-quick down ${interface}
        exit 0
    }

    trap shutdown TERM INT QUIT

    sleep infinity &
    wait $!
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "wireguard-client";
  contents = [
    entrypoint
    resolvconf
    pkgs.bashInteractive # for `podman exec`
    pkgs.coreutils
    pkgs.curl
    pkgs.dockerTools.caCertificates
    pkgs.iproute2
    pkgs.iputils
    pkgs.wireguard-tools
  ];
  extraCommands = ''
    mkdir -p bin etc/wireguard
    ln -sf ${pkgs.bashInteractive}/bin/bash bin/sh
  '';
  config = {
    Cmd = [ "${entrypoint}/bin/wireguard-client" ];
    Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt" ];
    # Confirms traffic is actually leaving through the tunnel.
    Healthcheck = {
      Test = [
        "CMD"
        "${pkgs.curl}/bin/curl"
        "-fsS"
        "-o"
        "/dev/null"
        "--max-time"
        "25"
        "https://api.ipify.org"
      ];
      Interval = 90000000000; # 90s, in nanoseconds
      Timeout = 30000000000;
      StartPeriod = 30000000000;
    };
  };
}
