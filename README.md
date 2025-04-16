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

### Post install

1. Change `firecat53` user passwords. 
2. Update sops key after reinstall. Commit and sync then rebuild.
```bash
nix shell nixpkgs#ssh-to-age nixpkgs#sops
ssh-keyscan <hostname> | ssh-to-age
# Set `&<hostname> age.....` in nixos-secrets/.sops.yaml
sops updatekeys nixos-secrets/<hostname>/secrets.yml
sops updatekeys nixos-secrets/common/secrets.yml
git add .sops.yaml <homename>/ && git commit -m 'Update sops keys'
```
        
3. `nix flake update` and rebuild flake on target machine after sops key is updated.
4. `sudo nmcli connection import type wireguard file /etc/wireguard/wg0.conf`
   for laptops/desktops
5. Update syncthing device ID's if necessary. Re-add servers on phones and
   wife's laptop if needed.
6. `echo nixos/flake.lock > ~/nixos/.stignore` (keep flake.lock from syncing)
        
## Minimal and Base Installs

1. See above [[#Installing on a New machine]]

## BACKUP server

1. See above [[#Installing on a New machine]]
2. `sudo smbpass -a jamia`
3. `ssh-keygen -f /etc/ssh/backup && chown backup: /etc/ssh/backup`. Change
   authorized_keys backup user in `backups.nix` for applicable machines and
   rebuild their flakes.
4. `sudo -i -u backup ssh -i /etc/ssh/backup <backup source hostname(s)>` and accept fingerprint

## LAPTOP/OFFICE desktop

1. See above [[#Installing on a New machine]]
2. Login to Vaultwarden
3. Login to Firefox Sync
4. Open Syncthing on this machine and other machines. Ensure syncing is setup.
5. Stow (dotfiles)
```bash
cd home/firecat53/docs/family/scott/src/dotfiles
stow -t /home/firecat53/ --dotfiles stow/
stow calibre gomuks music passwords python ssh-scotty
```
6. Add yazi plugins
```bash
ya pack -a yazi-rs/plugins:git
ya pack -a yazi-rs/plugins:smart-enter
ya pack -a yazi-rs/plugins:toggle-pane
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
