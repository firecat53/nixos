{
  inputs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./disko-config.nix
    ./hardware-configuration.nix
    ../modules/common
    ../modules/boot.nix
    #../modules/boot-grub.nix  # Grub required for Hetzner VPS CHANGEME
    ../../home-manager/home-manager.nix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  isRemote = true; # Define if directly exposed to the internet (not behind LAN firewall)
  isVirtual = true; # Define if a VPS/VM or container

  home-manager.users.firecat53 = {
    imports = [
      ../../home-manager/base.nix
    ];
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Swap (zram)
  zramSwap.enable = true;

  system.stateVersion = "26.05";
}
