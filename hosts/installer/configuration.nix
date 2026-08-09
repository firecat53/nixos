# Rescue / installer ISO.
#
# Avoid adding any modules that pull in sops secrets from my-secrets
#
# The flake source exits at /nixos on the ISO as plain text to copy and
# edit after booting.
{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./findiso.nix
    # Each verified secrets-free; see the header note.  ssh-keys.nix is not a
    # module - it is a plain attrset, consumed by sshd.nix for knownHosts and
    # below for authorizedKeys.
    ../modules/avahi.nix # so it answers to nixos.local without hunting for an IP
    ../modules/common/env.nix
    ../modules/common/packages.nix
    ../modules/common/sshd.nix
    ../modules/servers/neovim.nix
  ];

  # -- Boot from a loopback-mounted ISO on a multiboot USB key ---------------

  # findiso.nix re-implements findiso= for the systemd initrd.  Keep the
  # systemd initrd (the scripted one is removed in 26.11) - see that file.
  boot.initrd.systemd.enable = true;

  # -- ZFS -------------------------------------------------------------------

  # Needed to import/repair pools and to install a base-zfs host.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-id/";

  # Pin the channel-default kernel: it is the one nixpkgs keeps ZFS-compatible.
  # mkForce because the installer profiles may reach for a newer kernel, and a
  # ZFS-incompatible kernel is the most likely way an unattended build breaks.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # ZFS refuses to import without one.  Arbitrary; the installed host sets its
  # own in configuration.nix.
  networking.hostId = "0badc0de";

  # -- ISO contents ----------------------------------------------------------

  # inputs.self is the flake source as git tracks it: no .git, no untracked
  # files, no ignored files, and critically no flake *inputs*.
  isoImage.contents = [
    {
      source = inputs.self;
      target = "/nixos";
    }
  ];

  # Short and stable so grub/search.cfg derives basename "nixos" and picks up
  # grub/support/nixos.cfg on the Trusty key.
  isoImage.volumeID = "nixos-installer";

  # Must be image.baseName: the ISO builder derives the output filename from
  # it.  Setting image.fileName / isoImage.isoName instead looks like it works
  # (both evaluate to the new value) but the built file still comes out as
  # image.baseName + ".iso".  The name is different from the official
  # nixos-minimal-* images, and it is what installer-iso.nix's prune glob
  # matches on.
  # mkForce because iso-image.nix already defines baseName at normal priority.
  image.baseName = lib.mkForce "nixos-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  # -- Rescue kit ------------------------------------------------------------

  # common/packages.nix already brings bottom, curl, dua, fd, git, jq, lf,
  # nix-tree, pciutils, python3, ripgrep, rsync, screen, tmux, wget,
  # wireguard-tools and usbutils - not repeated here.
  environment.systemPackages =
    with pkgs;
    [
      # filesystems: create, check, repair
      btrfs-progs
      cryptsetup
      dosfstools
      e2fsprogs
      exfatprogs
      ntfs3g
      xfsprogs
      # partitioning
      gptfdisk
      parted
      # disk recovery / health
      ddrescue
      hdparm
      lsscsi
      nvme-cli
      smartmontools
      testdisk # also provides photorec
      # boot repair
      efibootmgr
      # hardware inventory
      dmidecode
      lm_sensors
      lshw
      # network troubleshooting
      dnsutils
      ethtool
      iperf3
      iw
      mtr
      nmap
      socat
      tcpdump
      traceroute
      # general
      file
      openssl
      p7zip
      pv
      tree
      unzip
      zip
      # installing a host from the tree at /nixos
      age
      nixos-install-tools
      sops
      inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
    ]
    ++ [ config.boot.kernelPackages.cpupower ];

  # -- Access ----------------------------------------------------------------

  # sshd itself, PasswordAuthentication=false and PermitRootLogin="no" all come
  # from common/sshd.nix, so authorize against the installer's `nixos` user
  # (created by installation-device.nix with passwordless sudo) rather than
  # root.  Public keys only.
  users.users.nixos.openssh.authorizedKeys.keys =
    lib.attrValues (import ../modules/common/ssh-keys.nix).devices;

  networking.networkmanager.enable = true;

  system.stateVersion = "26.05";
}
