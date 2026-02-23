# Disko configuration for homeserver
# Two NVMe drives in a mirrored ZFS rpool with systemd-boot on the first drive's ESP
#
# Partition layout (identical on both NVMe drives):
#   p1: 1G   EF00 ESP (vfat) - only first drive mounted as /boot
#   p2: 4G   legacy bpool partition (unused placeholder)
#   p3: ~1.8T rpool (ZFS mirror)
#   p4: 8G   encrypted swap
#
# NOTE: datapool is on separate SATA drives and is NOT managed by disko.
# Import it manually: sudo zpool import -f datapool
# Its mount is declared in hardware-configuration-disko.nix.
#
# WARNING: Do NOT run `disko --mode disko` on an existing system.
# It would reformat the drives. This config is used only as a NixOS module
# for fileSystems generation, and as a reference for future fresh installs.
{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.ace42e0026eed9c82ee4ac0000000001";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            bpool = {
              size = "4G";
              # Unused - legacy ZFS boot pool partition placeholder
              # Keeps partition numbering correct (ESP=p1, bpool=p2, rpool=p3, swap=p4)
            };
            rpool = {
              end = "-8G";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            encryptedSwap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
      nvme1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.ace42e0035b8defe2ee4ac0000000001";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              # Not mounted - only first drive's ESP used for systemd-boot
            };
            bpool = {
              size = "4G";
              # Unused - legacy ZFS boot pool partition placeholder
            };
            rpool = {
              end = "-8G";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            encryptedSwap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "zstd";
          devices = "on";
          dnodesize = "auto";
          mountpoint = "/";
          normalization = "formD";
          relatime = "on";
          xattr = "on";
        };
        datasets = {
          # System datasets
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
          };
          "nixos/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib";
          };
          "nixos/var/lib/containers" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/var/lib/containers/storage" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib/containers/storage";
          };
          "nixos/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/log";
          };

          # Data datasets
          "data" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "data/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "data/podman_volumes" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib/containers/storage/volumes";
          };
          "data/var_backups" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/backups";
          };
          "data/srv" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/srv";
          };

          # Media datasets
          "data/audiobooks" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/audiobooks";
          };
          "data/cameras" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/cameras";
          };
          "data/cameras-peggy" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/cameras-peggy";
          };
          "data/ebooks" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/ebooks";
          };
          "data/immich" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/immich";
          };
          "data/music" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/music";
          };
          "data/pictures" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/pictures";
          };
          "data/video" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/video";
          };
          "data/wallpaper" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/wallpaper";
          };
          "data/youtube" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/mnt/media/youtube";
          };

          # Reserved space to prevent pool from filling completely
          "reserved" = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options.refreservation = "10G";
          };
        };
      };
    };
  };
}
