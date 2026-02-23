# Hardware configuration for homeserver with disko
# This should replace hardware-configuration.nix when reinstalling with disko
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [
    "vmd"
    "xhci_pci"
    "ahci"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.tmp.useTmpfs = true;

  # No filesystem declarations for NVMe - disko handles that
  # Swap is also handled by disko configuration

  # datapool is on separate SATA drives (mirrored), not managed by disko
  fileSystems."/mnt/downloads" = {
    device = "datapool/downloads";
    fsType = "zfs";
    options = [ "X-mount.mkdir" ];
  };

  # External USB drive for restic backups
  fileSystems."/mnt/restic" = {
    device = "/dev/disk/by-label/RESTIC";
    fsType = "exfat";
    options = [
      "X-mount.mkdir"
      "nofail"
    ];
  };
}
