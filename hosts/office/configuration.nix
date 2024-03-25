# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ 
  inputs,
  ...
}:{
  imports =
    [ # Include the results of the hardware scan.
      ./disko-config.nix
      ./hardware-configuration.nix
      ./services
      ../modules/common
      ../modules/desktops
      ../modules/avahi.nix
      ../modules/boot-grub.nix
      ../modules/gnome.nix
      ../modules/podman.nix
      ../modules/sway.nix
      ../../home-manager/home-manager.nix
      ./paul.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
    ];

  home-manager.users.firecat53 = {
    imports = [
      inputs.sops-nix.homeManagerModule
      ../../home-manager/office.nix
    ];
  };

  networking.hostName = "office";
  networking.hostId = "65b24ecb";

  # Swap (zram)
  zramSwap.enable = true;

  # Polkit - for home-manager sway
  security.polkit.enable = true;

  system.stateVersion = "23.11";
}
