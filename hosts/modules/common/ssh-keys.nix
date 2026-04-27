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
  };

  # Passphraseless key used by the autossh SOCKS-proxy tunnel.
  # Authorized with restrict/permitopen/command=false on the homeserver.
  autossh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDd+IGsJFLaBeY5jJPMEDQlWUFyS42eqyjj+8A37kGP firecat53";

  # Backup pull user — runs on the backup host, authorized on machines it pulls from.
  backupPull = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup";
}
