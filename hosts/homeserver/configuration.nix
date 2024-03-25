# Main configuration
{
  inputs,
  lib,
  pkgs,
  ...
}: {
  # adjust according to your platform, such as
  imports = [
    ./hardware-configuration.nix
    ./services
    ../modules/common
    ../modules/servers
    ../modules/avahi.nix
    ../modules/libvirt.nix
    ../modules/podman.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "homeserver"; # Define your hostname.
  networking.hostId = "abcd1234";
  networking.firewall.trustedInterfaces = ["enp4s0" "wg0"];
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs = {
      "20-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
      };
    };
    networks = {
      "30-enp4s0" = {
        matchConfig.Name = "enp4s0";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-br0" = {
        matchConfig.Name = "br0";
        address = ["192.168.200.101/24"];
        gateway = ["192.168.200.1"];
        bridgeConfig = {};
        linkConfig = {
          RequiredForOnline = "routable";
        };
      };
      "wg0".address = ["10.200.200.6/24"];
    };
  };

  ### apcupsd
  services.apcupsd.enable = true;

  ### Add extra ssh-key homeserver_ed25519.pub (needed for autossh tunnel)
  users.users.firecat53.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFhp4/kDcUTbR1wmIqBgGV4L+7lhfJFA2LYP6fxbjbpl ed25519-key-20180530"
  ];

  ### Add extra media packages
  users.users.firecat53 = {
    packages = with pkgs; [
      exiftool
      ffmpeg
      gdu
      mediainfo
      par2cmdline
      unrar
    ];
  };

  system.stateVersion = "23.11";
}
