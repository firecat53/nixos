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

# Remote rebuild (from laptop to other hosts)
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

This is a NixOS flake configuration managing 6 hosts (laptop, office, homeserver, backup, vps).

### Directory Structure

- `flake.nix` - Entry point defining all inputs and `mkSystem` helper function
- `hosts/<hostname>/` - Per-host configurations
  - `configuration.nix` - Main host config
  - `hardware-configuration.nix` - Generated hardware config
  - `disko-config.nix` - Declarative disk partitioning
  - `services/` - Host-specific services (directory import)
- `hosts/modules/` - Shared NixOS modules
  - `common/` - Base config applied to all hosts (nix settings, users, sshd, sops)
  - `desktops/` - Desktop environment (Sway, fonts, pipewire, printing)
  - `servers/` - Server features (backups, fail2ban, wireguard)
  - Feature modules: `zfs.nix`, `docker.nix`, `podman.nix`, `libvirt.nix`, etc.
- `hosts/examples/` - Templates for new hosts (base-minimal, base-btrfs, base-zfs)
- `home-manager/` - User-level configurations
  - `home-manager.nix` - Passes flake inputs to home-manager
  - `common/` - Shared user tools
  - `apps/` - Optional applications
  - `sway/` - Sway window manager config
  - Role configs: `laptop.nix`, `homeserver.nix`, `office.nix`

### Key Patterns

**Host configuration imports:**
```nix
imports = [
  ./hardware-configuration.nix
  ./services/
  ../modules/common
  ../modules/<feature>.nix
  ../../home-manager/home-manager.nix
  inputs.home-manager.nixosModules.home-manager
  inputs.sops-nix.nixosModules.sops
];
```

**Custom options** (defined in `hosts/modules/common/options.nix`):
- `isRemote` (bool) - Set for hosts directly exposed to the internet (not behind the LAN firewall)
- `isVirtual` (bool) - Set for cloud/VM hosts
- `latestZFSKernel` (bool) - Use latest ZFS-compatible kernel

**Secrets management:**
- Uses sops-nix with age encryption
- Secrets stored in separate private repo at `~/nixos/nixos-secrets/`
- Decrypted using SSH host keys

**Package sources:**
- `pkgs` - nixos-26.05 stable
- `pkgs.unstable` - Latest unstable packages

### Related Repositories

```
~/nixos/
├── nixos/           # This repo
├── nixos-secrets/   # Private sops-encrypted secrets
└── nix-neovim/      # Custom Neovim flake
```
