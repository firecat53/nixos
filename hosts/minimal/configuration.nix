{
  inputs,
  ...
}:{
  imports =
    [ # Include the results of the hardware scan.
      ./disko-config.nix
      ./hardware-configuration.nix
      ../modules/common
      ../modules/boot.nix
      ../../home-manager/home-manager.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
    ];

  home-manager.users.firecat53 = {
    imports = [
      ../../home-manager/minimal.nix
    ];
  };

  networking.hostName = "nixos";
  networking.hostId = "65b44e8b";
  networking.networkmanager.enable = true;

  # Swap (zram)
  zramSwap.enable = true;

  system.stateVersion = "24.11";
}
