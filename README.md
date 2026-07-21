# NixOS configurations

> NOTE: Code moved to https://git.firecat53.me/firecat53/nixos. Issues and PRs
> still accepted here for now. Github repo maintained as a read-only mirror.

## Machines

* Laptop `laptop`
* Homeserver `homeserver`
* Backup server `backup`
* VPS cloud server `vps`
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

## Update flow

`flake.lock` is committed, and `~/nixos` (including `.git`) is synced to every
host via syncthing — syncthing is the git transport; nothing pulls from
forgejo.

* **Lock bumps**: the `flake-lock-update` timer on `homeserver`
  (`hosts/homeserver/services/flake-lock-update.nix`) runs `nix flake update
  --commit-lock-file` in a throwaway worktree of `main` at 04:00 daily.
  Syncthing propagates the commit before the 04:40 `system.autoUpgrade` window.
* **Servers** (`homeserver`, `backup`, `vps`) auto-upgrade from
  `~/nixos/nixos?ref=main` — exactly what main's lock records, nothing newer.
* **Desktops** (`laptop`, `office`) auto-upgrade from the working tree
  (usually `dev`, uncommitted changes included). Rebase `dev` onto `main` to
  pick up lock bumps.
* **Debugging/rollback**: `git log -p flake.lock` on main shows what every
  server was running on a given day; revert a lock-bump commit to roll the
  fleet back.

Day-to-day testing is unchanged: edit anywhere, syncthing syncs, and
`nixos-rebuild test/switch --flake .#<host>` builds the dirty tree. A manual
`nix flake update` shows up as a modified `flake.lock` — commit or discard it
deliberately.

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

## Adding / removing services and hosts

### Which name goes where (the 2am map)

| name                                               | served by                                      | reachable from       | what it's for                                                                                                       |
| -------------------------------------------------- | ---------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `*.lan.firecat53.net`                              | homeserver Traefik                             | LAN + wireguard only | the "home" name every homeserver web app gets (real LE certs, but the name resolves to a LAN address)               |
| `*.firecat53.me`                                   | VPS Traefik                                    | internet             | public front door: proxies over wireguard to the homeserver `.lan` name, or to a VPS-local port                     |
| `*.firecat53.com`                                  | VPS Traefik                                    | internet             | VPS-native public apps (grafana, VPS nextcloud, syncthing, Authelia portal, apex website)                           |
| `firecat53.net` + subs (`matrix.`, `s.`, `nc.`, …) | homeserver Traefik directly (443 port-forward) | internet             | federated/public apps that must be reached directly (Matrix, Akkoma, Nextcloud) — hand-written, not in the registry |

Rules of thumb:

- **At home or on wireguard** → use the `.lan` name. Direct to the homeserver,
  no VPS hop; basicAuth prompt if the service has one.
- **Out in the world** → use the `.me` name. The VPS terminates TLS, Authelia
  2FA's you (if `auth = true`), then proxies over wireguard to the *same*
  homeserver backend.
- `.lan` and `.me` are two doors to one app — the entry in
  `hosts/modules/service-registry.nix` is what ties them together.
- **Service on the VPS itself** → `.me` if it's registry-managed (behind
  Authelia), `.com` if it's hand-written and fully public.
- Not web / not HTTP isn't covered by any of this: ssh, syncthing sync, and
  wireguard are direct port openings on their hosts; Forgejo ssh
  (`git.firecat53.me:2222`) is a TCP passthrough on the VPS Traefik
  (`proxy-me.nix`) to the homeserver.

### Web services (`*.lan.firecat53.net` + `*.firecat53.me`)

Standard web services on both hosts are driven by a single shared registry,
`hosts/modules/service-registry.nix`. Derived from it:

| consumer                            | generates                                                          |
| ----------------------------------- | ------------------------------------------------------------------ |
| homeserver `services/lan-proxy.nix` | the `.lan` Traefik routers/services (+ `-me`/`-noauth` companions) |
| vps `services/proxy-me.nix`         | the `*.firecat53.me` reverse-proxy routers/services                |
| vps `services/authelia.nix`         | 2FA-protected domains (`auth = true`) + access_control rules       |
| vps `services/gatus.nix`            | homeserver `.lan` backend resolution for monitoring                |
| homeserver `services/dashboard.nix` | build-time assertion that dashboard tiles point at real services   |

Each entry's fields — the attr name is the `*.firecat53.me` subdomain, and
every flag controls exactly **one** generated thing (nothing is derived from
another flag):

| field       | where           | meaning                                                                  |
|-------------|-----------------|--------------------------------------------------------------------------|
| `lan`       | homeserver sets | the `.lan` router host, and the backend the VPS proxies to over wireguard |
| `port`      | all             | backend port on localhost                                                |
| `url`       | all             | backend URL; overrides `port` for non-localhost backends (e.g. hass VM)  |
| `auth`      | homeserver/vps  | `true` gates `<sub>.firecat53.me` behind Authelia 2FA                    |
| `passHost`  | homeserver      | VPS forwards the real `*.firecat53.me` Host header (see below)           |
| `meRouter`  | homeserver      | homeserver companion router on `<sub>.firecat53.me` (see below)          |
| `basicAuth` | homeserver      | homeserver router gets the `auth` basicAuth middleware                   |
| `vpsBypass` | homeserver      | homeserver `-noauth` companion router skipping basicAuth for VPS traffic |
| `rules`     | homeserver/vps  | optional; per-service Authelia `access_control` rules (see below)        |

**Service running on homeserver:**

1. Create `hosts/homeserver/services/<name>.nix` defining *just the app*
   (bound to a localhost port), and add it to
   `hosts/homeserver/services/default.nix`. No Traefik config.
2. Add one entry to the `homeserver` set in the registry (or `lanOnly` for
   services that should not be exposed at `*.firecat53.me`):
   ```nix
   <sub> = { lan = "<sub>.lan.firecat53.net"; port = <port>; auth = <true|false>; };
   ```
3. Rebuild `homeserver`, then `vps`. The `.lan` router, the
   `<sub>.firecat53.me` router, the Authelia rule (if `auth = true`), and
   Gatus resolution appear automatically.

To inspect the fully-rendered result of the generated config:

```bash
nix eval --json .#nixosConfigurations.<host>.config.services.traefik.dynamicConfigOptions | jq
```

**Services with their own HTTP basic auth** (`basicAuth = true` — e.g. gollum,
today, syncthing, transmission): the auth model is *basicAuth on the LAN,
Authelia on the internet* — not both. The VPS proxies `*.firecat53.me` traffic
in from `10.200.200.5`, so set `vpsBypass = true` to generate a companion
router that matches that source IP and omits the `auth` middleware, letting
Authelia-2FA'd requests (and Gatus probes) through without a second prompt.
LAN/wireguard clients keep hitting the plain `Host()` router and still get
basicAuth. This relies on the homeserver Traefik not trusting forwarded
headers (so `ClientIP` is the real TCP source). Services without basicAuth
(app-level login, or `auth = false`) need no companion router.

**Apps that build absolute redirects/URLs from the Host header** (e.g. gollum,
sonarr, OAuth redirect flows): the `ClientIP` trick won't work, because the
backend would see the `.lan` host and redirect clients there (broken off-LAN).
Instead set `passHost = true` so the VPS forwards the real
`<sub>.firecat53.me` host, plus `meRouter = true` to generate the homeserver
companion router keyed on that host (no `ClientIP` needed — only the VPS ever
sends that host, already 2FA'd, so it carries no basicAuth).

**Service running locally on the VPS:**

1. Create `hosts/vps/services/<name>.nix` (+ add it to `services/default.nix`),
   binding the app to a localhost port.
2. Add one entry to the `vps` set in the registry:
   ```nix
   <sub> = { port = <port>; auth = <true|false>; };
   ```
3. Rebuild `vps`.

**Removing a service:** delete its registry entry (and the service file + its
`default.nix` import). The `.lan` router, proxy router, auth rule, and monitor
resolution all disappear with it — and the dashboard assertion fails at build
time if a tile still points at it. Remove OIDC from authelia.nix if necessary.

**Oddballs stay hand-written** in their own service files (path-prefix rules,
extra middlewares, non-`.lan` hosts): matrix-synapse, akkoma, nextcloud, and
the nginx `lan.firecat53.net` apex. If a service outgrows the registry schema,
move it to a hand-written stanza rather than adding fields.

### Authelia: access control and OIDC

**Access Control rules**: `auth = true` entries get a blanket `two_factor` rule.
To override that for specific paths (e.g. keep some public), add a `rules` list
to the entry — Authelia `access_control` rules evaluated *before* the blanket
rule, first match wins. Omit each rule's `domain`; `authelia.nix` derives it
from the attr name. For example, Microbin uses this to keep paste viewing public
but require authentication for submitting/delting pastes.

**OIDC** (apps that log in *through* Authelia rather than forward-auth, e.g.
immich, audiobookshelf): the client is defined in
`identity_providers.oidc.clients` in `authelia.nix` (hashed `client_secret` +
`redirect_uris`), and the app stores the plaintext secret in its own sops
secret. This pair is cross-host (Authelia on the VPS, app on the homeserver), so
it is *not* registry-derived. See the secret-generation commands at the top of
`authelia.nix`.

### Hosts

To add a host:

1. Add it to `flake.nix` (`mkSystem`).
2. Set its wireguard address in the host's `configuration.nix`
   (`networks."wg0".address`).
3. Add its wireguard/LAN IPs to `networking.hosts` in
   `hosts/modules/desktops/networking.nix`.
4. Add sops keys (see the install/post-install sections below).
5. Install per [General Install Procedures](#general-install-procedures).

## General Install Procedures

### Tips

1. Generate hostId (for ZFS systems): `head -c4 /dev/urandom | od -A none -t x4`
2. Hetzner VMs apparently require grub instead of systemd-boot (as of 2025-08)
3. Available options (defined in `hosts/modules/common/options.nix`):
    a. isRemote (bool) - set for hosts directly exposed to the internet (not
       behind the LAN firewall). Controls the wireguard endpoint and keeps
       LAN-only ports (e.g. Eternal Terminal 2022) closed publicly. Default false.
    b. isVirtual (bool) - set for virtual hardware (VPS or VM). Disables
       hardware-specific services (fwupd, smartd). Default false.
    c. latestZFSKernel (bool) - set to use latest available ZFS compatible kernel. Default false.
    d. tmuxStatusColor (str) - tmux status bar background color, for per-host
       visual distinction. Default "#cba6f7" (catppuccin mocha mauve).

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
        
5. *existing host* After the sops key is updated, refresh the secrets input's
   lock entry and rebuild on the target machine (commit the lock change):
```bash
nix flake update my-secrets
```
6. *new host* `sudo nmcli connection import type wireguard file
   /etc/wireguard/wg0.conf`
   for networkmanager.
7. Update syncthing device ID's if necessary. Re-add servers on phones and
   wife's laptop if needed.
        
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


#### Recovery from failed drive (e.g. nvme0 failed)

1. Boot: enter the firmware boot menu and select the second NVMe drive. It boots
   via EFI/BOOT/BOOTX64.EFI (the removable-media fallback).
2. Replace the dead drive in the ZFS mirror:
   - `sudo zpool replace rpool <old-nvme0-part3> /dev/disk/by-id/<new>-part3`
3. Recreate the ESP on the replacement drive and let the next rebuild resync:
   - `sudo mkfs.vfat -F32 -n ESP /dev/disk/by-id/<new>-part1`
   - `sudo nixos-rebuild boot --flake .#homeserver`  # repopulates /boot

### VPS (cloud server)

1. [Install using nixos-anywhere](#installing-using-nixos-anywhere)
