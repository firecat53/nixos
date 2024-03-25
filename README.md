# NixOS configurations

* Laptop
* Homeserver
* Backup server
* VPS cloud server
* Office secondary/spare laptop

Sops-nix secrets live in a private repository `nixos-secrets`.

History for this repository starts as of when I removed the last of my
secrets/keys/etc (2024-03-25). Prior history exists but only in local branches.
This branch is kept updated using `git cherry-pick` (unless I decide to just
delete the existing history).

## Tips

1. Generate hostId: `head -c4 /dev/urandom | od -A none -t x4`

## After install

1. Change `firecat53` user passwords. 
2. Update sops key after reinstall. Commit and sync then rebuild.
    
        nix shell nixpkgs#ssh-to-age nixpkgs#sops
        ssh-keyscan <hostname> | ssh-to-age
        # Set `&<hostname> age.....` in nixos-secrets/.sops.yaml
        sops updatekeys nixos-secrets/<hostname>/secrets.yml
        git add .sops.yaml <homename>/ && git commit -m 'Update sops keys'
        
3. `nix flake update` and rebuild flake on target machine after sops key is updated.
4. `sudo nmcli connection import type wireguard file /etc/wireguard/wg0.conf`
   for laptops/desktops
5. Update syncthing device ID's if necessary. Re-add servers on phones and
   wife's laptop if needed.
        
# BACKUP server

## Install

1. Boot installer.
2. Mount flash drive DATA
3. Install:

        mkdir ./mnt
        sudo -i
        mount /dev/sd(x)3 /home/nixos/mnt
        cat /home/nixos/mnt/dotfiles/ssh-scotty/.ssh/id_ed25519.pub /root/.ssh/authorized_keys
        # Login via ssh from another machine (e.g. ssh root@192.168.200.103)
        nix-shell -p git
        mount -o remount,size=8G /run/user/0  ## This is to prevent out of space error during build
        # Update device(s) in /home/nixos/backup/modules/disko-config.nix
        nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /home/nixos/mnt/nixos/nixos/hosts/backup/disko-config.nix
        nixos-generate-config --no-filesystems --show-hardware-config --root /mnt --dir /home/nixos/mnt/nixos/nixos/hosts/backup/
        nixos-install --flake /home/nixos/mnt/nixos/nixos#backup
        cp -a /home/nixos/mnt/nixos /mnt/home/firecat53/ && chown -R 20000:100 /home/mnt/firecat53/nixos
        umount /mnt/boot
        umount /mnt
        zfs export rpool
        systemctl reboot

4. `sudo smbpass -a jamia`
8. `ssh-keygen -f /etc/ssh/backup && chown backup: /etc/ssh/backup`. Change
   authorized_keys backup user in `backups.nix` for applicable machines and
   rebuild their flakes.
9. `sudo -i -u backup ssh -i /etc/ssh/backup <backup source hostname(s)>` and accept fingerprint

# LAPTOP with encrypted ZFS root (single disk)

* Creates 4 partitions: 1-1Gb EFI, 2-2Gb bpool, 3-rpool, 4-1 Mib BIOS
* No swap partition - will use ZRAM
* Creates two zfs pools:
    * bpool -> bpool/boot
    * rpool (encrypted)
      - rpool/nixos/{root,home,/var/lib,/var/lib/containers/storage,/var/log}
      - rpool/data/home

```
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

# VPS (cloud server)

## Install

1. Create new (Ubuntu is fine) cloud server. Add one of the public keys. Adjust
   DNS 'A' records if needed.
2. SSH into the new box and update the disk device name(s) and partition layout
   in disko-config.nix.
3. Reboot into the
   [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md) kexec image

        curl -L https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root /root/kexec/run

4. From the laptop, run `nix run github:nix-community/nixos-anywhere -- --flake .#vps root@firecat53.com`
5. If problems arise, add `--no-reboot` to the above command so you can
   troubleshoot the new install.
