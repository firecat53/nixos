{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_840_EVO_120GB_S1D7NEAF411408R";
        content = {
          type = "gpt";
          partitions = {
            GRUB = {
              size = "1M";
              type = "EF02";
            };
            BOOT = {
              size = "512M";
              type = "0700";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
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
        mode = "";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          devices = "off";
          dnodesize = "auto";
          encryption = "on";
          keyformat = "passphrase";
          keylocation = "prompt";
          mountpoint = "none";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
        };
        datasets = {
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
          };
          "nixos/root/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib";
          };
          "nixos/root/var/lib/containers" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root/var/lib/containers/storage" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root/var/lib/containers/storage/volumes" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib/containers/storage/volumes";
          };
          "data" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "data/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
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
