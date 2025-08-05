# Update CHANGEME before use.
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "CHANGEME";
        content = {
          type = "gpt";
          partitions = {
            GRUB = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              end = "-8G"; # CHANGEME if necessary. Swap size.
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
          compression = "on";
          devices = "off";
          dnodesize = "auto";
          #encryption = "on";  # CHANGEME uncomment next 3 lines for encryption
          #keyformat = "passphrase";
          #keylocation = "prompt";
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
            options.mountpoint = "none";
          };
          "nixos/var/lib/containers/storage/volumes" = {
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
