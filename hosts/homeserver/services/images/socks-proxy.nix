# sshd used as a SOCKS proxy entry point into the wireguard pod's namespace.
{
  pkgs,
  suffix ? "",
}:
let
  inherit (pkgs) lib;

  sshKeys = import ../../../modules/common/ssh-keys.nix;

  user = "firecat53";
  # Host keys are generated on first start and kept on a volume so they survive
  # image rebuilds (the alpine image baked them in and changed them every build).
  keyDir = "/var/lib/socks-proxy";

  # Tunnel only: no shell, no pty, no agent or X11 forwarding.
  authorizedKeys = pkgs.writeText "authorized_keys" ''
    command="${pkgs.coreutils}/bin/false",no-pty,no-X11-forwarding,no-agent-forwarding,no-user-rc ${sshKeys.autosshKey}
  '';

  sshdConfig = pkgs.writeText "sshd_config" ''
    AllowTcpForwarding yes
    AuthorizedKeysFile /etc/ssh/%u
    ClientAliveCountMax 1000
    ClientAliveInterval 30
    HostKey ${keyDir}/ssh_host_ed25519_key
    KbdInteractiveAuthentication no
    PasswordAuthentication no
    PermitRootLogin no
    PidFile none
    TCPKeepAlive yes
    UsePAM no
  '';

  entrypoint = pkgs.writeShellScriptBin "socks-proxy" ''
    set -e
    mkdir -p ${keyDir}
    if [ ! -f ${keyDir}/ssh_host_ed25519_key ]; then
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -f ${keyDir}/ssh_host_ed25519_key
    fi
    exec ${pkgs.openssh}/bin/sshd -D -e -f ${sshdConfig}
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "socks-proxy${suffix}";
  contents = [
    entrypoint
    pkgs.bashInteractive # for `podman exec`
    pkgs.coreutils
    pkgs.openssh
  ];
  extraCommands = ''
    mkdir -p bin sbin etc/ssh var/empty ${lib.removePrefix "/" keyDir}
    ln -sf ${pkgs.bashInteractive}/bin/bash bin/sh
    # sshd refuses the login outright if the account's shell doesn't exist.
    ln -sf ${pkgs.shadow}/bin/nologin sbin/nologin

    cp ${authorizedKeys} etc/ssh/${user}
    chmod 0444 etc/ssh/${user}

    # sshd needs both the login user and its own privilege separation user.
    cat > etc/passwd <<EOF
    root:x:0:0:root:/root:/bin/sh
    sshd:x:22:22:sshd:/var/empty:/sbin/nologin
    ${user}:x:1000:1000::/home/${user}:/sbin/nologin
    EOF
    cat > etc/group <<EOF
    root:x:0:
    sshd:x:22:
    ${user}:x:1000:
    EOF
  '';
  config = {
    Cmd = [ "${entrypoint}/bin/socks-proxy" ];
    ExposedPorts = {
      "22/tcp" = { };
    };
  };
}
