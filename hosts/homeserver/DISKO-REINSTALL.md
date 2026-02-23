# Homeserver Disko Configuration Guide

This directory contains disko configuration for the homeserver's two-NVMe-drive
mirrored ZFS setup with systemd-boot.

## Current Layout

Both NVMe drives have identical partition layouts:

| Part | Size  | Purpose                          |
|------|-------|----------------------------------|
| p1   | 1G    | EF00 ESP (vfat) - /boot on nvme0 |
| p2   | 4G    | Unused (legacy bpool placeholder) |
| p3   | ~1.8T | rpool (ZFS mirror)               |
| p4   | 8G    | Encrypted swap                   |

- **rpool**: Mirrored across both NVMe drives
- **ESP**: Only the first drive's ESP is mounted at `/boot` (systemd-boot)
- **datapool**: Separate SATA drives (not managed by disko)

## Safety Information

**WARNING**: Do NOT run `disko --mode disko` on an existing system. It would
reformat the drives. The disko config is used only as a NixOS module for
fileSystems generation, and as a reference for future fresh installs.

## Scenario A: Fresh Install (Empty Drives)

### 1. Boot into NixOS installer

### 2. Clone your configuration

```bash
git clone <your-repo-url> /tmp/nixos-config
cd /tmp/nixos-config
```

### 3. Review and adjust disko-config.nix

Check these settings in `hosts/homeserver/disko-config.nix`:

- **Disk devices**: Update device paths to match your drives
- **Partition sizes**: Adjust if needed (swap=8G, rpool uses remaining space)
- **Pool/dataset options**: Modify compression, reservation, etc. as desired

### 4. Run disko to partition and format

```bash
sudo nix run github:nix-community/disko -- --mode disko /tmp/nixos-config/hosts/homeserver/disko-config.nix
```

This will:
- Partition both NVMe drives
- Create the mirrored rpool ZFS pool and all datasets
- Format the ESP partition
- Set up encrypted swap on both drives

**Note**: This does NOT touch the SATA drives (datapool). Import datapool
separately after install.

### 5. Install NixOS

Disko automatically mounts everything to `/mnt`.

```bash
sudo nixos-install --flake /tmp/nixos-config#homeserver
```

### 6. Reboot

```bash
reboot
```

### 7. Post-install

```bash
sudo zpool import -f datapool
```

## Scenario B: Fresh Install + Migrate Data via zfs send/recv

### 1-4. Follow Scenario A steps 1-4

Run disko to partition, create pools, and mount everything. This creates empty datasets.

### 5. Receive ZFS data into the new pools

Before installing NixOS, populate the datasets with your data:

```bash
# Import the old/backup pool with an alternate name
sudo zpool import -R /tmp/oldpool oldrpool

# Recursive send of all data datasets
sudo zfs snapshot -r oldrpool/data@migrate
sudo zfs destroy -r rpool/data
sudo zfs send -R oldrpool/data@migrate | sudo zfs recv rpool/data

# Fix mountpoints to use legacy (disko expects legacy mounts)
sudo zfs set mountpoint=legacy rpool/data/home
sudo zfs set mountpoint=legacy rpool/data/podman_volumes
# ... etc for each dataset
```

**Note**: You generally don't need to migrate system datasets (`rpool/nixos/*`)
since NixOS will rebuild those during install. Focus on the `rpool/data/*`
datasets. datapool lives on separate SATA drives - just import it directly.

After migrating, re-mount everything:

```bash
sudo umount -R /mnt
sudo nix run github:nix-community/disko -- --mode mount /tmp/nixos-config/hosts/homeserver/disko-config.nix
```

### 6. Clean up and install

```bash
sudo zpool export oldrpool
sudo nixos-install --flake /tmp/nixos-config#homeserver
reboot
```

## Current Files

- `disko-config.nix` - Disko disk configuration (two NVMe drives, mirrored rpool)
- `hardware-configuration-disko.nix` - Hardware config (non-disko mounts: datapool, restic)
- `hardware-configuration.nix` - Old hardware config (GRUB + bpool, kept for reference)
- `configuration.nix` - Main configuration (imports disko-config.nix + boot.nix)
