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
    ../modules/zfs.nix
    ../../home-manager/home-manager.nix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  home-manager.users.firecat53 = {
    imports = [
      ../../home-manager/base.nix
    ];
  };

  networking.hostName = "nixos";
  networking.hostId = "2ea7c7fb";
  networking.networkmanager.enable = true;

  # Swap (zram)
  zramSwap.enable = true;

  system.stateVersion = "25.05";
}
