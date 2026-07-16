{
  inputs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./disko-config.nix
    ./hardware-configuration.nix
    ../modules/boot.nix
    #../modules/boot-grub.nix  # Grub required for Hetzner VPS CHANGEME
    ../modules/common/options.nix
    ../modules/common/nix.nix
    ../modules/common/sshd.nix
    ../modules/common/users.nix
    inputs.disko.nixosModules.disko
  ];

  isRemote = true; # Define if directly exposed to the internet (not behind LAN firewall)
  isVirtual = true; # Define if a VPS/VM or container

  networking.hostName = "nixos";

  # Swap (zram)
  zramSwap.enable = true;

  system.stateVersion = "26.05";
}
