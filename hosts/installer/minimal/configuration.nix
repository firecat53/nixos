# Stage-1 install target: `nixos-install --flake .#minimal`.
#
# ./hardware-configuration.nix is a placeholder that gets regenerated in place
# during the install.  Stage 2 switches to the real host config.
{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/avahi.nix
    ../../modules/boot.nix
    ../../modules/common/env.nix
    ../../modules/common/nix.nix
    ../../modules/common/options.nix
    ../../modules/common/packages.nix
    ../../modules/common/sshd.nix
    ../../modules/common/tz_locale.nix
    ../../modules/common/users.nix
  ];

  networking.hostName = "minimal";

  # Arbitrary; stage 2 sets the host's real one.
  networking.hostId = "0badc0de";

  # -- ZFS -------------------------------------------------------------------

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id/";

  # Opposite of the ISO's setting, deliberately.  A stage-1 system is usually
  # importing a pool last touched by the machine being replaced, and refusing
  # to boot at that point is worse than the risk this guards against.
  boot.zfs.forceImportRoot = true;

  # The channel-default kernel is the one nixpkgs keeps ZFS-compatible, and a
  # stage-1 system that will not boot is worthless.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  networking.networkmanager.enable = true;

  # Enough to finish the sops rekey from here if it was not done from the ISO.
  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
  ];

  system.stateVersion = "26.05";
}
