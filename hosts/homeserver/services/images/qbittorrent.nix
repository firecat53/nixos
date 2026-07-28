# qbittorrent-nox, running in the wireguard pod's network namespace.
{ pkgs }:
let
  inherit (pkgs) lib;

  # Seed config for a fresh /config volume; qbittorrent owns the file after that.
  # Pinning the session to wireguard0 is what keeps traffic off a leaked default
  # route. The alpine image rewrote `Preferences/Connection\Interface` from
  # `ip route get` on every start, but qbittorrent 5.x reads these keys instead,
  # so that was writing to a dead key.
  defaultConfig = pkgs.writeText "qBittorrent.conf" ''
    [BitTorrent]
    Session\Interface=wireguard0
    Session\InterfaceName=wireguard0

    [LegalNotice]
    Accepted=true

    [Preferences]
    WebUI\ReverseProxySupportEnabled=true
    WebUI\ServerDomains=*
  '';

  entrypoint = pkgs.writeShellScriptBin "qbittorrent" ''
    set -e
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.python3 # search plugins
        pkgs.qbittorrent-nox
      ]
    }

    CONF="$HOME/qBittorrent/qBittorrent.conf"
    umask 002

    if [ ! -f "$CONF" ]; then
        mkdir -p "$HOME/qBittorrent"
        cp ${defaultConfig} "$CONF"
        chmod 644 "$CONF" # store files are read-only
    fi

    exec qbittorrent-nox
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "qbittorrent";
  contents = [
    entrypoint
    pkgs.bashInteractive # for `podman exec`
    pkgs.coreutils
    # Tracker announces are mostly https; without these every one of them fails
    # certificate verification.
    pkgs.dockerTools.caCertificates
    pkgs.qbittorrent-nox
  ];
  extraCommands = ''
    mkdir -p bin config data etc
    ln -sf ${pkgs.bashInteractive}/bin/bash bin/sh

    cat > etc/passwd <<EOF
    root:x:0:0:root:/root:/bin/sh
    qbittorrent:x:1000:100::/config:/bin/sh
    EOF
    cat > etc/group <<EOF
    root:x:0:
    users:x:100:
    EOF
  '';
  # Matches the `user = "1000:100"` the container runs as, so a fresh volume
  # comes up owned correctly.
  fakeRootCommands = ''
    chown -R 1000:100 config data
  '';
  config = {
    Cmd = [ "${entrypoint}/bin/qbittorrent" ];
    Env = [
      "HOME=/config"
      "XDG_CONFIG_HOME=/config"
      "XDG_DATA_HOME=/config"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
      "SSL_CERT_DIR=/etc/ssl/certs"
    ];
    WorkingDir = "/config";
    Volumes = {
      "/config" = { };
      "/data" = { };
    };
  };
}
