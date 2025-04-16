# NixOS configurations

* Laptop `laptop`
* Homeserver `homeserver`
* Backup server `backup`
* VPS cloud server `vps`
* Office secondary/spare desktop `office`
* Base flake install w/ home-manager and sops. Encrypted LUKS (btrfs) or ZFS
    - `base-btrfs` or `base-zfs`
* Bare minimum flake install for testing. `minimal`

Sops-nix secrets live in a private repository `nixos-secrets`.

History for this repository starts as of when I removed the last of my
secrets/keys/etc (2024-03-25). Prior history exists but only in local branches.
This branch is kept updated using `git cherry-pick` (unless I decide to just
delete the existing history).

## General Install Procedures

### Tips

1. Generate hostId: `head -c4 /dev/urandom | od -A none -t x4`

### Installing on a new machine

1. Boot installer.
2. Mount flash drive DATA
3. Install:
```bash
mkdir ./mnt
sudo mount /dev/sdx3 /home/nixos/mnt
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

### Post install

1. Change `firecat53` user passwords. 
2. Update sops key after reinstall. Commit and sync then rebuild.
```bash
nix shell nixpkgs#ssh-to-age nixpkgs#sops
ssh-keyscan <hostname> | ssh-to-age
# Set `&<hostname> age.....` in nixos-secrets/.sops.yaml
sops updatekeys nixos-secrets/<hostname>/secrets.yml
git add .sops.yaml <homename>/ && git commit -m 'Update sops keys'
```
        
3. `nix flake update` and rebuild flake on target machine after sops key is updated.
4. `sudo nmcli connection import type wireguard file /etc/wireguard/wg0.conf`
   for laptops/desktops
5. Update syncthing device ID's if necessary. Re-add servers on phones and
   wife's laptop if needed.
        
## Minimal and Base Installs

1. See above [[#Installing on a New machine]]

## BACKUP server

1. See above [[#Installing on a New machine]]
2. `sudo smbpass -a jamia`
3. `ssh-keygen -f /etc/ssh/backup && chown backup: /etc/ssh/backup`. Change
   authorized_keys backup user in `backups.nix` for applicable machines and
   rebuild their flakes.
4. `sudo -i -u backup ssh -i /etc/ssh/backup <backup source hostname(s)>` and accept fingerprint

## OFFICE desktop

1. See above [[#Installing on a New machine]]
2. Login to Vaultwarden
3. Login to Firefox Sync
4. Open Syncthing on this machine and other machines. Ensure syncing is setup.
5. Add yazi plugins
```bash
ya pack -a yazi-rs/plugins:git
ya pack -a yazi-rs/plugins:smart-enter
ya pack -a yazi-rs/plugins:toggle-pane
```
6. Dotfiles

## LAPTOP with encrypted ZFS root (single disk)

* Creates 4 partitions: 1-1Gb EFI, 2-2Gb bpool, 3-rpool, 4-1 Mib BIOS
* No swap partition - will use ZRAM
* Creates two zfs pools:
    * bpool -> bpool/boot
    * rpool (encrypted)
      - rpool/nixos/{root,home,/var/lib,/var/lib/containers/storage,/var/log}
      - rpool/data/home

```bash
disk="/dev/disk/by-id/xxxxxx"
MNT="$(mktemp -d)"

## Partitioning
blkdiscard -f "${disk}" || true

parted --script --align=optimal  "${disk}" -- \
    mklabel gpt \
    mkpart EFI 1MiB 1GiB \
    mkpart bpool 1GiB 5GiB \
    mkpart rpool 5GiB 100% \
    mkpart BIOS 0% 1MiB \
    set 1 esp on \
    set 4 bios_grub on \
    set 4 legacy_boot on

partprobe "${disk}"
udevadm settle

## ZFS
zpool create -o compatibility=grub2 \
   -o ashift=12 \
   -o autotrim=on \
   -O acltype=posixacl \
   -O canmount=off \
   -O compression=lz4 \
   -O devices=off \
   -O normalization=formD \
   -O relatime=on \
   -O xattr=sa \
   -O mountpoint=none \
   -R "${MNT}" \
   bpool /dev/disk/by-label/bpool

zfs create -o canmount=on -o mountpoint=legacy  bpool/boot

zpool create \
   -o ashift=12 \
   -o autotrim=on \
   -O acltype=posixacl \
   -O canmount=off \
   -O compression=lz4 \
   -O devices=off \
   -O dnodesize=auto \
   -O normalization=formD \
   -O relatime=on \
   -O xattr=sa \
   -O mountpoint=none \
   -O encryption=on -O keylocation=prompt -O keyformat=passphrase \
   -R "${MNT}" \
   rpool /dev/disk/by-label/rpool

zfs create -o canmount=off -o mountpoint=none rpool/nixos
zfs create -o canmount=on -o mountpoint=legacy rpool/nixos/root
zfs create -o canmount=off -o mountpoint=none rpool/nixos/var
zfs create -o canmount=on -o mountpoint=legacy rpool/nixos/var/lib
zfs create -o canmount=on -o mountpoint=legacy rpool/nixos/var/log
zfs create -o canmount=off -o mountpoint=none rpool/nixos/var/lib/containers
zfs create -o canmount=off -o mountpoint=none rpool/nixos/var/lib/containers/storage
zfs create -o canmount=on -o mountpoint=legacy rpool/nixos/var/lib/containers/storage/volumes
zfs create -o canmount=off -o mountpoint=none rpool/data
zfs create -o canmount=on -o mountpoint=legacy rpool/data/home
zfs create -o canmount=off -o mountpoint=none -o refreservation=1G rpool/reserved

## Mount
mount -t zfs rpool/nixos/root "${MNT}"/
mkdir -p "${MNT}/home" "${MNT}/boot" "${MNT}/var/log" "${MNT}/var/lib/"
mount -t zfs rpool/data/home "${MNT}/home"

mkfs.vfat -n EFI /dev/disk/by-label/EFI  ## TODO - this might not work right or might see wrong drive CAUTION
mount -t zfs bpool/boot "${MNT}/boot"
mkdir "${MNT}/boot/efi"
mount -t vfat /dev/disk/by-label/EFI "${MNT}/boot/efi"

mount -t zfs rpool/nixos/var/lib "${MNT}/var/lib"
mount -t zfs rpool/nixos/var/log "${MNT}/var/log"

mkdir -p "${MNT}/var/lib/containers/storage/volumes"
mount -t zfs rpool/nixos/var/lib/containers/storage/volumes "${MNT}/var/lib/containers/storage/volumes"
```
## Homeserver

1. TODO

## VPS (cloud server)

1. Create new (Ubuntu is fine) cloud server. Add one of the public keys. Adjust
   DNS 'A' records if needed.
2. SSH into the new box and update the disk device name(s) and partition layout
   in disko-config.nix.
3. Reboot into the
   [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md) kexec image
```bash
curl -L https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root /root/kexec/run
```
4. From the laptop, run `nix run github:nix-community/nixos-anywhere -- --flake .#vps root@firecat53.com`
5. If problems arise, add `--no-reboot` to the above command so you can
   troubleshoot the new install.
