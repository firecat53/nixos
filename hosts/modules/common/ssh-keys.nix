{
  # Per-device SSH public keys. Generate one keypair per device with:
  #   ssh-keygen -t ed25519 -C "firecat53@<device>" -f ~/.ssh/id_ed25519
  # Then paste the .pub contents below.
  #
  # Rotation: remove the device's entry here and rebuild — that revokes it
  # everywhere it's authorized.
  devices = {
    laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXRehLyz1GOSoo1u4IhbFJA7db1oyDzVIl+52H3TNsC firecat53@laptop";
    office = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZf9V1ivL7hlsX2QkhPCMn51DyJveUZTSmls+YxJaVF firecat53@office";
    chryspie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRcoLrRPQcvGHFJ1VpD2yBOg2s3HXlnbFSCNkCjkBb6 chryspie@chryspie-Lenovo-YOGA-710-15IKB";
  };

  # Passphraseless key used by the autossh SOCKS-proxy tunnel.
  # Locked down with restrict/permitopen/command=false
  autossh = ''restrict,permitopen="127.0.0.1:2222",command="/run/current-system/sw/bin/false" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDd+IGsJFLaBeY5jJPMEDQlWUFyS42eqyjj+8A37kGP firecat53'';

  # Backup pull user — runs on the backup host, authorized on machines it pulls from.
  backupPull = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup";

  # Host keys from `ssh-keyscan -t ed25519 <host>`. Applied as
  # programs.ssh.knownHosts in sshd.nix so ssh verifies all my hosts
  hostKeys = {
    backup = {
      extraHostNames = [
        "192.168.200.103"
        "10.200.200.4"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF3/lm6KPyPTKEeBDMxkLkVLZA8GWBWrEJIwg8x+M1Z";
    };
    hass = {
      extraHostNames = [
        "192.168.200.102"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDs5UDiWKj/Sf6ki72DrNtsBWhYiAFJOAz9DAOt7FQWo";
    };
    homeserver = {
      extraHostNames = [
        "192.168.200.101"
        "10.200.200.6"
        "lan.firecat53.net"
        "firecat53.net"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINe/I1ay/pp2nqJlF+m1yCEcxiNvg9tc+WynujnzTqcD";
    };
    laptop = {
      extraHostNames = [
        "192.168.200.103"
        "10.200.200.4"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5X6Pzsva4vmheELcJd7FHZwI4uvqSgypsiRZfO2ONA";
    };
    office = {
      extraHostNames = [
        "192.168.200.104"
        "10.200.200.7"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAr75ajY0cUEuKU69MhP/wU2WJM/lbErWJxeuQwfyq9h";
    };
    router = {
      extraHostNames = [
        "192.168.200.1"
        "10.200.200.1"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfapJqu2CXwWZJ6y2VdhP70iGLKRIiuJUVeJFEKBh34";
    };
    vps = {
      extraHostNames = [
        "firecat53.com"
        "10.200.200.5"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfapJqu2CXwWZJ6y2VdhP70iGLKRIiuJUVeJFEKBh34";
    };
  };
}
