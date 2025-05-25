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
    ../modules/common/users.nix
    inputs.disko.nixosModules.disko
  ];

  networking.hostName = "nixos";

  # Swap (zram)
  zramSwap.enable = true;

  system.stateVersion = "25.05";
}
