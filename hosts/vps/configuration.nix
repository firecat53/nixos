# Main configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  # adjust according to your platform, such as
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./services
    ../modules/common
    ../modules/servers
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  # Grub needed for Hetzner VPS with ZFS on root
  boot.loader.grub.enable = true;
  boot.supportedFilesystems= ["zfs"];
  boot.zfs.extraPools = ["datapool"];

  fileSystems = { 
    "/var/lib" = {
      device = "datapool/var-lib";
      fsType = "zfs";
      options = ["X-mount.mkdir"];
    };
    "/home/firecat53/shared" = {
      device = "datapool/shared";
      fsType = "zfs";
      options = ["X-mount.mkdir"];
    };
  };

  networking.hostName = "vps"; # Define your hostname.
  networking.hostId = "6a315305";
  networking.useDHCP = false;
  networking.firewall.trustedInterfaces = ["enp1s0" "wg0"];
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
    networks."wg0".address = ["10.200.200.5/24"];
  };

  # Override default smartmon enable
  services.smartd.enable = lib.mkForce false;
 
  system.stateVersion = "23.05"; # Did you read the comment?
}
