# Binary cache for the other hosts. sshd serves this store read-only via
# `nix-store --serve` under an unprivileged `nix-ssh` account (no shell, no
# forwarding), so nothing new is exposed and auth is the per-host key already
# in ssh-keys.nix.
#
# Clients reject unsigned paths whatever the transport, so this host signs
# everything it builds — including the per-host toplevels flake-lock-update
# builds nightly. Paths built before this was enabled stay unsigned; see the
# README for the one-time `nix store sign --all`.
{
  config,
  lib,
  outputs,
  ...
}:
let
  inherit (import ../../modules/common/ssh-keys.nix) hostKeys;

  # Every deployed host except this one, so adding a host authorizes it here.
  # Intersecting the two sources needs no exclusion list: the install-media
  # targets have no host key, and the non-NixOS entries in hostKeys (router,
  # hass, forgejo) are not nixosConfigurations.
  clients = lib.filter (h: h != config.networking.hostName && hostKeys ? ${h}) (
    lib.attrNames outputs.nixosConfigurations
  );
in
{
  sops.secrets.nix-cache-key = { };
  nix.settings.secret-key-files = [ config.sops.secrets.nix-cache-key.path ];

  nix.sshServe = {
    enable = true;
    # Host keys, not the user keys in `devices`: substitution runs in
    # nix-daemon as root, which has no agent and never reads ~/.ssh.
    keys = map (h: hostKeys.${h}.publicKey) clients;
  };
}
