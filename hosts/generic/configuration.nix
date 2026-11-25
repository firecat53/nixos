# Generic server for testing hardware or VMs; desktop.nix adds a GUI.
# Self-contained except for ssh-keys.nix. No sops, home-manager or
# autoUpgrade. Install from the ISO (see README "Generic installs"):
#
#   sudo disko-install --flake .#generic-server --disk main /dev/<disk>
{
  inputs,
  modulesPath,
  pkgs,
  ...
}:
let
  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  imports = [
    inputs.disko.nixosModules.disko
    # Broad initrd module set in place of a generated hardware-configuration.nix
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  # -- Disk ------------------------------------------------------------------

  # Overridden by `disko-install --disk main /dev/<disk>`. Mounts use
  # partlabels, so the installed system never references this path.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        # For switching to grub on BIOS-only machines
        GRUB = {
          size = "1M";
          type = "EF02";
        };
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        ROOT = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsOpts;
              };
            };
          };
        };
      };
    };
  };

  zramSwap.enable = true;

  # -- Boot / hardware -------------------------------------------------------

  # UEFI only. For BIOS: boot.loader.grub = { enable = true; device = "/dev/<disk>"; };
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;
  # Optimus laptops where nouveau locks up the machine (e.g. Yoga 710, GM108):
  # boot.blacklistedKernelModules = [ "nouveau" ];

  services.btrfs.autoScrub.enable = true;
  services.fwupd.enable = true;
  # Only starts when the virtio port exists, so harmless on bare metal
  services.qemuGuest.enable = true;

  # -- Network ---------------------------------------------------------------

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Reachable as nixos.local
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # -- Users -----------------------------------------------------------------

  users.users.firecat53 = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # initial password: firecat53
    initialHashedPassword = "$6$4uca2AGtTNxwo1bt$JJwaaNTqKF6ddXE9xLqWdmTZpElZZ5KNHEbj4jqAVY5QVknWKB4lCvzlMPZ0VLivh8FcmpGbkx5bVJhT1URpz0";
    openssh.authorizedKeys.keys = builtins.attrValues (import ../modules/common/ssh-keys.nix).devices;
  };

  # -- Nix -------------------------------------------------------------------

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "firecat53"
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nixpkgs.config.allowUnfree = true;

  # -- Packages / locale -----------------------------------------------------

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  environment.systemPackages = with pkgs; [
    bottom
    curl
    dmidecode
    dua
    fd
    git
    jq
    kitty.terminfo
    lf
    lm_sensors
    lshw
    nix-tree
    nvme-cli
    pciutils
    python3
    ripgrep
    rsync
    screen
    smartmontools
    stress-ng
    tmux
    usbutils
    wget
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
