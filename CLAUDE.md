# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Format all Nix files
nix fmt

# Rebuild system (replace <hostname> with: laptop, homeserver, backup, vps, office)
sudo nixos-rebuild switch --flake .#<hostname>

# Dry-run to preview changes
sudo nixos-rebuild dry-activate --flake .#<hostname>

# Remote rebuild (from desktops to other hosts). Use this for urgent deploys
# instead of waiting for the 04:40 auto-upgrade window. --build-host ships the
# flake and its resolved inputs, so the target needs no checkout.
nixos-rebuild switch --flake .#<hostname> --target-host <hostname> --build-host <hostname> --sudo

# Update all flake inputs
nix flake update

# Update specific input
nix flake update <input-name>

# Deploy to cloud server via nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config \
  ./hosts/<host>/hardware-configuration.nix \
  --flake .#<host> --target-host root@<ip>
```

## Architecture

This is a NixOS flake configuration managing 5 hosts (laptop, office, homeserver, backup, vps).

### Key Patterns

**Custom options** (defined in `hosts/modules/common/options.nix`):
- `isRemote` (bool) - Set for hosts directly exposed to the internet (not behind the LAN firewall)
- `isVirtual` (bool) - Set for cloud/VM hosts
- `latestZFSKernel` (bool) - Use latest ZFS-compatible kernel

**Secrets management:**
- Uses sops-nix with age encryption
- Secrets stored in a separate private repo, consumed as the `my-secrets` flake
  input over ssh (`git+ssh://forgejo/firecat53/nixos-secrets`). Push changes
  before `nix flake update my-secrets` will see them.
- Decrypted using SSH host keys, which double as the read-only forgejo deploy
  keys used to fetch that input

**Update flow:** all five hosts auto-upgrade at 04:40 from committed `main` on
forgejo, not from a local checkout. See the README's "Update flow" section.

**Package sources:**
- `pkgs` - nixos-26.05 stable
- `pkgs.unstable` - Latest unstable packages

### Related Repositories

Clones on the desktops (`laptop`, `office`); the servers pull from forgejo by URL.

```
~/nixos/
├── nixos/           # This repo
├── nixos-secrets/   # Private sops-encrypted secrets
└── nix-neovim/      # Custom Neovim flake
```
