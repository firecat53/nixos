# Main configuration
{
  inputs,
  lib,
  ...
}:
{
  # adjust according to your platform, such as
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./services
    ../modules/common
    ../modules/podman.nix
    ../modules/servers/backups.nix
    ../modules/servers/fail2ban.nix
    ../modules/servers/neovim.nix
    ../modules/servers/tmux.nix
    ../modules/zfs.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  isVirtual = true; # Define if a VPS/VM or container

  # Grub needed for Hetzner VPS
  boot.loader.grub.enable = true;
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "pangolin"; # Define your hostname.
  networking.hostId = "353051a6";
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # Override default smartmon enable
  services.smartd.enable = lib.mkForce false;

  system.stateVersion = "25.11"; # Did you read the comment?
}
