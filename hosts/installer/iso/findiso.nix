# Restore loopback-ISO booting (findiso=) under the systemd initrd.
#
# Upstream's findiso lived in boot.initrd.postDeviceCommands, which only the
# scripted initrd ever ran.  That implementation is deprecated and scheduled
# for removal in 26.11, so this reimplements the same idea as a systemd initrd
# unit.  Import into an ISO built from installation-cd-*.nix.
#
# The stock ISO fstab mounts /iso from /dev/disk/by-label/${volumeID}, which
# only exists when the ISO is a real block device.  We deliberately do NOT
# override that: once the ISO file is attached to a loop device, udev probes
# it, reads the same iso9660 label, and creates the by-label symlink itself.
# The stock entry then resolves with nothing else changed.
#
# GRUB needs no changes either - iso-image.nix already emits
#   if [ ${iso_path} ] ; then set isoboot="findiso=${iso_path}" ; fi
# into EFI/BOOT/grub.cfg even with the systemd initrd, so a loopback-aware
# bootloader that sets $iso_path gets findiso= on the kernel line for free.
{ ... }:
{
  boot.initrd.kernelModules = [ "loop" ];

  # Stage 1 has to be able to mount whatever filesystem the ISO is sitting on.
  boot.initrd.supportedFilesystems = [
    "ext4"
    "vfat"
    "exfat"
  ];

  # losetup, mount, umount, udevadm and blkid are all already in the stock
  # initrd's bin env, so no extraBin is needed here.
  boot.initrd.systemd = {
    services.findiso = {
      description = "Attach the boot ISO named by findiso= to a loop device";

      # The /iso mount pulls in a .device unit for the by-label symlink.  That
      # device job's timeout starts as soon as the transaction is built, not
      # when the mount is reached, so this has to finish well inside it
      # (90s by default).  Scanning a handful of partitions takes ~seconds.
      wantedBy = [ "initrd-fs.target" ];
      before = [ "sysroot-iso.mount" ];

      # Needs udev up so /dev/disk/by-uuid/* is populated.
      after = [ "systemd-udevd.service" ];
      requires = [ "systemd-udevd.service" ];

      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -u

        findiso=
        for param in $(cat /proc/cmdline); do
          case "$param" in
            findiso=*) findiso="''${param#findiso=}" ;;
          esac
        done

        if [ -z "$findiso" ]; then
          echo "findiso: not requested, booting normally"
          exit 0
        fi

        mkdir -p /findiso

        # USB mass storage can take tens of seconds to enumerate, and
        # After=systemd-udevd.service only means udevd is *running* - not that
        # it has probed any block devices.  Without this retry the scan runs to
        # completion in ~40ms against an empty /dev/disk/by-uuid and gives up
        # long before the key shows up.  Budget stays inside the 90s device-unit
        # job timeout that sysroot-iso.mount is already racing.
        deadline=$(( $(date +%s) + 60 ))

        while :; do
          udevadm settle --timeout=5 || true

          for dev in /dev/disk/by-uuid/*; do
            [ -e "$dev" ] || continue
            mount -o ro "$dev" /findiso 2>/dev/null || continue

            if [ -f "/findiso$findiso" ]; then
              echo "findiso: found $findiso on $dev"
              losetup --read-only --find "/findiso$findiso"
              # Deliberately leave /findiso mounted: it is the loop device's
              # backing store.  Unmounting it here would yank the ISO away.
              udevadm settle --timeout=30
              exit 0
            fi

            umount /findiso
          done

          [ "$(date +%s)" -lt "$deadline" ] || break
          sleep 1
        done

        echo "findiso: $findiso not found on any device" >&2
        echo "findiso: devices present at giveup:" >&2
        ls -l /dev/disk/by-uuid/ >&2 || true
        exit 1
      '';
    };
  };
}
