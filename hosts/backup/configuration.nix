# Main configuration
{
  inputs,
  ...
}: {
  # adjust according to your platform, such as
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./services
    ../modules/common
    ../modules/servers
    ../modules/boot.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "backup"; # Define your hostname.
  networking.hostId = "fedd1234";
  networking.useDHCP = false;
  networking.firewall.trustedInterfaces = ["eno1" "wg0"];
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "eno1";
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
    networks."wg0".address = ["10.200.200.4/24"];
  };

  boot.zfs.extraPools = ["backuppool"];

  system.stateVersion = "23.11";
}
