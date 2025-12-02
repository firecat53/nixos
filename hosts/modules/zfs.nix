# ZFS configs/backups
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Find latest available NixOS kernel compatible with ZFS
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  # Note this might jump back and forth as kernels are added or removed.
  boot.kernelPackages = lib.mkIf config.latestZFSKernel latestKernelPackage;

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      forceImportRoot = false;
      devNodes = "/dev/disk/by-id/";
    };
  };

  environment.systemPackages = with pkgs; [
    lzop
    mbuffer
    pv
  ];

  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
}
