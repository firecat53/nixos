let
  # Passphraseless key used by the autossh SOCKS-proxy tunnel. Authorized twice:
  # here on the host, and inside the socks-proxy image.
  autosshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDd+IGsJFLaBeY5jJPMEDQlWUFyS42eqyjj+8A37kGP firecat53";
in
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

  inherit autosshKey;

  # The autossh key as authorized on the host: it may only open the hop to the
  # socks-proxy container, and gets no shell. 2223 is the parallel test pod
  # (temporary, along with qbittorrent-test.nix).
  autossh = ''restrict,permitopen="127.0.0.1:2222",permitopen="127.0.0.1:2223",command="/run/current-system/sw/bin/false" ${autosshKey}'';

  # Backup pull user — runs on the backup host, authorized on machines it pulls from.
  backupPull = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup";

  # Host keys from `ssh-keyscan -t ed25519 <host>`. Applied as
  # programs.ssh.knownHosts in sshd.nix so ssh verifies all my hosts
  hostKeys = {
    # forgejo's ssh endpoint, for root's non-interactive my-secrets fetch.
    # RSA because that's the only host key forgejo serves.
    forgejo = {
      hostNames = [ "[git.firecat53.me]:2222" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhO0zKdedUKsVHz4oIRGboTX66fJFV1q5I+zSO46tdGax/X00bL4j18r4KErSmyotllxjVaQG5kgxYtLa8mSWFR0dl8hdHRXNy3zsTgAytvlhGw8dPuScYoOatUZzSXHmjECcdDr/U3vfu6pQmnoZLswJMUOd0jhGP75edpG/g5wgK79fkAsF6Zbj34Z7IhWWeOm/4oxYPuYD0z7vepp0bGJhNGb+XbHSmWGc3KlOxND+2XGVVT//b21cYrREa/f8kBDga2PwDx+bsOv+pZAi7koGixCoXLvH38VLqD6akaU588Jyecjvj9kEMsVcXz6BTHlxUhMB+IOgfF7Eyl4r6VEFzziLdIeFa4YjxCHRI947FbVR189lMeEz+wXeN9H7/eceXjwENpOb2rYbcEmxvOjpHXNWnhU3gC1m1VfdBF8VJP5NbrUFuqINSNm4urRemSC0c+HiBZUalAxftzdxW2cjb6ookN6ewLA6dsVAskAuRmcMdrsREAx/kYC9c6TVW1hs9OKdrYNKq9IwG9sDMLeVSd9r/vUZ43wo816V22UViobHDgtToRZKYOmnjJ5pECEXVwNlkCnobPk5wWp/MP4Cz7GfQS5T0LFiZS/36L3+hIdp2YT4T5I8nYI/jGlzxwDFJOjsmaBYP4ILG+Ma+PhdN/wKn5uH+4hgAIJGWOQ==";
    };
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
        "10.200.200.2"
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
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4xnaUvyhgK7fEsxuvKhNjcf6jBjPgU5oL6ITy7WPlo";
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
