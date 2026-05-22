# NixOS configurations

> NOTE: Code moved to https://git.firecat53.me/firecat53/nixos. Issues and PRs
> still accepted here for now. Github repo maintained as a read-only mirror.

## Machines

* Laptop `laptop`
* Homeserver `homeserver`
* Backup server `backup`
* VPS cloud server `vps`
* Pangolin cloud server `pangolin`
* Office secondary/spare desktop `office`
* Examples:
    + Flake install w/ home-manager and sops.
        - Encrypted or unencrypted `base-btrfs` or `base-zfs`
    + Bare minimum flake install for testing. `base-minimal`

Sops-nix secrets live in a private repository `nixos-secrets`. My directory
structure is:
```text
~/nixos
    ~/nixos/nixos/
    ~/nixos/nixos-secrets
    ~/nixos/nix-neovim
```

## Local packages

`pkgs/` contains derivations for small one-off apps maintained alongside this
repo. Each lives in `pkgs/<name>/` with its own `default.nix`, and is wired up
through `pkgs/default.nix` (`{ pkgs }: { ... = pkgs.callPackage ./<name> {}; }`).
Service modules consume them with
`localPkgs = import ../../../pkgs { inherit pkgs; }`.

### Local Package list

* `today` — minimal Flask webapp for quick diary, workout, and book entries into
  the wiki. Deployed on `homeserver` via `hosts/homeserver/services/today.nix`
  at `today.lan.firecat53.net`.

## General Install Procedures

### Tips

1. Generate hostId (for ZFS systems): `head -c4 /dev/urandom | od -A none -t x4`
2. Hetzner VMs apparently require grub instead of systemd-boot (as of 2025-08)
3. Available options:
    a. isVirtual (bool) - set for virtual hardware (VPS or VM). Default false.
    b. latestZFSKernel (bool) - set to use latest available ZFS compatible kernel. Default false.

### Installing using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md)

1. Create new (Ubuntu is fine) cloud server. Add one of the public keys. Adjust
   DNS 'A' records if needed.
2. SSH into the new box and update the disk device name(s) and partition layout
   (if needed) in disko-config.nix.
3. `nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hosts/<host>/hardware-configuration.nix --flake .#<host> --target-host root@<ip or domain>`
4. If problems arise, add `--no-reboot` to the above command so you can
   troubleshoot the new install.
5. [[#post-install]]

### Installing locally on a new machine using the ISO installer

1. Boot installer.
2. Mount flash drive DATA
3. Install:
```bash
mkdir ./mnt
sudo mount /dev/disk/by-label/DATA /home/nixos/mnt
rsync -av mnt/nixos .
cat /home/nixos/mnt/dotfiles/ssh-scotty/.ssh/id_ed25519.pub | sudo tee /root/.ssh/authorized_keys
# OR sudo passwd root
```
Login via ssh from another machine (e.g. ssh root@192.168.200.103)
```bash
nix-shell -p git
mount -o remount,size=8G /run/user/0  ## This is to prevent out of space error during build
# Update device(s) in ~/mnt/nixos/nixos/hosts/<host>/disko-config.nix
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /home/nixos/mnt/nixos/nixos/hosts/<host>/disko-config.nix
nixos-generate-config --no-filesystems --show-hardware-config --root /mnt --dir /home/nixos/mnt/nixos/nixos/hosts/<host>/
nixos-install --flake /home/nixos/mnt/nixos/nixos#<host>
cp -a /home/nixos/mnt/nixos /mnt/home/firecat53/ && chown -R 20000:100 /home/mnt/firecat53/nixos
umount /mnt/boot
umount /mnt
zfs export rpool
systemctl reboot
```
5. [[#post-install]]

### SSH key generation (new or rebuilt host)

Each desktop/laptop host gets its own SSH keypair — private halves never leave
the box, only pubkeys land in `hosts/modules/common/ssh-keys.nix`. Sequence
matters because the host can't reach itself via key auth until its pubkey is
authorized elsewhere.

1. **On the new/rebuilt host**, generate the device key as `firecat53`:
```bash
ssh-keygen -t ed25519 -C "firecat53@<hostname>" -f ~/.ssh/id_ed25519
wl-copy < ~/.ssh/id_ed25519.pub
```
2. **On a working host with repo access**, paste the pubkey into
   `hosts/modules/common/ssh-keys.nix` under the matching `devices.<host>`
   attribute. Commit and push.
3. Add the device pubkey to:
    a. GitHub / forgejo account (web UI) — needed for git operations
    b. HomeAssistant `~/.ssh/authorized_keys` for the `root` user
    c. Any other external service the host needs to reach
4. Rebuild every host that should authorize this device:
5. *(Desktops/laptops using the autossh tunnel only)* The passphraseless
   autossh private key is shared across all tunnel clients and lives in
   sops as `autossh-key`. Add it to the host's sops file (the matching
   pubkey is already in `ssh-keys.nix` as `autossh`, authorized on
   homeserver). To rotate, generate one new keypair, update `autossh` in
   `ssh-keys.nix`, and re-encrypt `autossh-key` into every desktop sops file.

### Post install

1. *new host* Change `firecat53` user and root (only for local machine) passwords. 
2. *new host* Generate SSH keys per [SSH key generation](#ssh-key-generation-new-or-rebuilt-host) above.
3. *existing host* Sync ~/nixos/ directory to new machine (including nixos configs and secrets)
4. *existing host* Update sops key after reinstall. Commit and sync then rebuild.
```bash
nix shell nixpkgs#ssh-to-age nixpkgs#sops
ssh-keyscan <hostname> | ssh-to-age
# Set `&<hostname> age.....` in nixos-secrets/.sops.yaml
sops updatekeys nixos-secrets/<hostname>/secrets.yml
sops updatekeys nixos-secrets/common/secrets.yml
git add .sops.yaml <homename>/ && git commit -m 'Update sops keys'
```
        
5. *existing host* `nix flake update` and rebuild flake on target machine after
   sops key is updated.
6. *new host* `sudo nmcli connection import type wireguard file
   /etc/wireguard/wg0.conf`
   for networkmanager.
7. Update syncthing device ID's if necessary. Re-add servers on phones and
   wife's laptop if needed.
8. *existing host* `echo nixos/flake.lock > ~/nixos/.stignore` (keep flake.lock
   from syncing)
        
## Specific host instructions

### Minimal and Base Installs

1. Copy/rename desired exmaple directory to hosts/xxxxx.
2. Update CHANGEME items (disk device id, disk encryption, etc).
3. Update configuration as desired.
    a. If using base-btrfs with encryption, rename `disko-config-luks.nix` to
    `disko-config.nix`
4. Add new host to flake.nix.
5. Sops-nix (if needed):
    a. Add any sops-nix keys to nixos-secrets/xxxx/secrets.yml
    b. Add new host to nixos-secrets/.sops.yml
    c. `sops updatekeys` happens after install
    d. Update flake inputs
6. [Install using nixos-anywhere](#installing-using-nixos-anywhere)

### BACKUP server

1. [[#Installing locally on a new machine using the ISO installer]]
2. `sudo smbpass -a jamia`
3. `ssh-keygen -f /etc/ssh/backup && chown backup: /etc/ssh/backup`. Change
   `backupPull` to the public key in `ssh-keys.nix` and rebuild all servers.
4. `sudo -i -u backup ssh -i /etc/ssh/backup <backup source hostname(s)>` and
   accept fingerprint

### LAPTOP/OFFICE desktops

1. [[#Installing locally on a new machine using the ISO installer]]
2. Login to Vaultwarden
3. Login to Firefox Sync
    a. Extensions - ClearURLs, floccus, Gnome Shell integration, Proxy
    SwitchyOmega 3, Stylus, uBlock Origin, User-Agent switcher and Manager,
    Vimium
4. Open Syncthing on this machine and other machines. Ensure syncing is setup.
5. Stow (dotfiles)
```bash
cd home/firecat53/docs/family/scott/src/dotfiles
stow -t /home/firecat53/ --dotfiles stow/
stow gomuks music passwords python ssh-scotty
```
 
### Homeserver

#### Disko (WARNING: instructions not completely verified working yet)

This directory contains disko configuration for homeserver's two-NVMe-drive
mirrored ZFS setup with systemd-boot.

##### Current Layout

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

##### Safety Information

**WARNING**: Do NOT run `disko --mode disko` on an existing system. It would
reformat the drives. The disko config is used only as a NixOS module for
fileSystems generation, and as a reference for future fresh installs.

##### Scenario A: Fresh Install (Empty Drives)

1. Boot into NixOS installer

2. Clone your configuration

```bash
git clone <your-repo-url> /tmp/nixos-config
cd /tmp/nixos-config
```

3. Review and adjust disko-config.nix

Check these settings in `hosts/homeserver/disko-config.nix`:

- **Disk devices**: Update device paths to match your drives
- **Partition sizes**: Adjust if needed (swap=8G, rpool uses remaining space)
- **Pool/dataset options**: Modify compression, reservation, etc. as desired

4. Run disko to partition and format

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

5. Install NixOS

Disko automatically mounts everything to `/mnt`.

```bash
sudo nixos-install --flake /tmp/nixos-config#homeserver
```

6. Reboot

```bash
reboot
```

7. Post-install

```bash
sudo zpool import -f datapool
```

##### Scenario B: Fresh Install + Migrate Data via zfs send/recv

1-4. Follow Scenario A steps 1-4

Run disko to partition, create pools, and mount everything. This creates empty datasets.

5. Receive ZFS data into the new pools

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

6. Clean up and install

```bash
sudo zpool export oldrpool
sudo nixos-install --flake /tmp/nixos-config#homeserver
reboot
```

### VPS (cloud server)

1. [Install using nixos-anywhere](#installing-using-nixos-anywhere)

### Pangolin (cloud server)

1. [Install using nixos-anywhere](#installing-using-nixos-anywhere)
2. Restore any backups to /var/lib/{pangolin,traefik} if desired.
3. `sudo zfs allow backup destroy,hold,mount,send,snapshot rpool/nixos/var/lib`
    a. Also create backuppool/pangolin/var on `backup` server
