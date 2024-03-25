# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  zfsRoot.partitionScheme = {
    biosBoot = "-part5";
    efiBoot = "-part1";
    swap = "-part4";
    bootPool = "-part2";
    rootPool = "-part3";
  };
  zfsRoot.devNodes = "/dev/disk/by-id/"; # MUST have trailing slash! /dev/disk/by-id/
  zfsRoot.bootDevices = (import ./machine.nix).bootDevices;
  zfsRoot.mirroredEfi = "/boot/efis/";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_blk"
    "ehci_pci"
    "nvme"
    "uas"
    "sd_mod"
    "sr_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "kvm-amd"];
  boot.extraModulePackages = [];
  boot.tmp.useTmpfs = true;

  fileSystems =
    {
      "/" = {
        device = "rpool/nixos/root";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/home" = {
        device = "rpool/data/home";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/var/lib" = {
        device = "rpool/nixos/var/lib";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/var/lib/containers/storage/volumes" = {
        device = "rpool/data/podman_volumes";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/var/log" = {
        device = "rpool/nixos/var/log";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/boot" = {
        device = "bpool/nixos/root";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/audiobooks" = {
        device = "rpool/data/audiobooks";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/cameras" = {
        device = "rpool/data/cameras";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/ebooks" = {
        device = "rpool/data/ebooks";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/music" = {
        device = "rpool/data/music";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/pictures" = {
        device = "rpool/data/pictures";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/video" = {
        device = "rpool/data/video";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/media/wallpaper" = {
        device = "rpool/data/wallpaper";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/srv" = {
        device = "rpool/data/srv";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/var/backups" = {
        device = "rpool/data/var_backups";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };

      "/mnt/downloads" = {
        device = "downloadpool/downloads";
        fsType = "zfs";
        options = ["X-mount.mkdir"];
      };
    }
    // (builtins.listToAttrs (map (diskName: {
        name = zfsRoot.mirroredEfi + diskName + zfsRoot.partitionScheme.efiBoot;
        value = {
          device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.efiBoot;
          fsType = "vfat";
          options = [
            "x-systemd.idle-timeout=1min"
            "x-systemd.automount"
            "noauto"
            "nofail"
          ];
        };
      })
      zfsRoot.bootDevices));

  swapDevices =
    map (diskName: {
      device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.swap;
      discardPolicy = "both";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    })
    zfsRoot.bootDevices;

  boot.supportedFilesystems = ["zfs"];
  boot.loader.efi.efiSysMountPoint = with builtins; (zfsRoot.mirroredEfi + (head zfsRoot.bootDevices) + zfsRoot.partitionScheme.efiBoot);
  boot.zfs.extraPools = ["backup" "backup1"];
  boot.zfs.devNodes = zfsRoot.devNodes;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generationsDir.copyKernels = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.configurationLimit = 15;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.extraInstallCommands = with builtins; (toString (map (diskName:
    "${pkgs.coreutils-full}/bin/cp -r "
    + config.boot.loader.efi.efiSysMountPoint
    + "/EFI"
    + " "
    + zfsRoot.mirroredEfi
    + diskName
    + zfsRoot.partitionScheme.efiBoot
    + "\n")
  (tail zfsRoot.bootDevices)));
  boot.loader.grub.devices =
    map (diskName: zfsRoot.devNodes + diskName) zfsRoot.bootDevices;
}
