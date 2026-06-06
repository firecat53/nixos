# Mirror the systemd-boot ESP (/boot, on nvme0) to nvme1's ESP partition.
#
# rpool is a ZFS mirror across both NVMe drives, so the OS and data survive a
# single drive failure. Only nvme0's ESP is mounted at /boot so without
# this the machine won't boot if nvme0 dies. This keeps a bootable copy of the
# ESP on nvme1.
#
# systemd-boot has no native ESP mirroring (unlike GRUB's mirroredBoots), so we
# rsync the ESP on every activation. `bootctl install` writes the removable-media
# fallback EFI/BOOT/BOOTX64.EFI in addition to EFI/systemd/, and rsync copies it,
# so the synced partition is directly bootable from the firmware boot menu.
#
{ pkgs, ... }:
let
  # nvme1's ESP partition (the backup target). nvme0's ESP is mounted at /boot.
  backupEsp = "/dev/disk/by-id/nvme-eui.ace42e0026eed9c82ee4ac0000000001-part1";

  syncScript = pkgs.writeShellScript "esp-sync" ''
    set -euo pipefail
    PATH=${
      pkgs.lib.makeBinPath [
        pkgs.util-linux # mount, umount, mountpoint
        pkgs.rsync
        pkgs.coreutils
      ]
    }

    if [ ! -e "${backupEsp}" ]; then
      echo "esp-sync: backup ESP ${backupEsp} not found, skipping" >&2
      exit 0
    fi
    if ! mountpoint -q /boot; then
      echo "esp-sync: /boot is not mounted, skipping" >&2
      exit 0
    fi

    target="$(mktemp -d)"
    cleanup() {
      umount "$target" 2>/dev/null || true
      rmdir "$target" 2>/dev/null || true
    }
    trap cleanup EXIT

    mount -t vfat -o umask=0077 "${backupEsp}" "$target"

    # vfat ignores unix ownership/perms; --modify-window=2 tolerates FAT's
    # 2-second timestamp granularity so unchanged files aren't recopied.
    rsync -rtL --delete --no-perms --no-owner --no-group \
      --modify-window=2 /boot/ "$target/"

    sync
    echo "esp-sync: /boot mirrored to ${backupEsp}"
  '';
in
{
  # Runs on every nixos-rebuild switch/boot (and at boot) so the backup ESP
  # always matches the running generation.
  system.activationScripts.espSync = {
    text = "${syncScript}";
    deps = [ ];
  };
}
