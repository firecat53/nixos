{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = "firecat53";
  upgradeFlake = "git+https://git.firecat53.me/firecat53/nixos.git?ref=main";
in
{
  nix.settings = {
    # Enable flakes
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Trusted users
    trusted-users = [
      "root"
      "${user}"
    ];
    download-buffer-size = 500000000;
  };

  # Enable git
  programs.git = {
    enable = true;
    config = {
      # For `sudo nixos-rebuild --flake .#<host>` off a local checkout.
      safe."directory" = [ "/home/${user}/nixos/nixos" ];
    };
  };

  # Add unstable to flake registry to use locally (e.g. `nix run nixpkgs-unstable#hatch`)
  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "olm-3.2.16" # Required by gomuks
    ];
  };

  # `pkgs.unstable.<name>` for packages needed from nixos-unstable
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        inherit (config.nixpkgs) config;
      };
    })
  ];

  environment.shellAliases = {
    # Show nix updates
    nd = ''
      nix profile diff-closures --profile /nix/var/nix/profiles/system |
            awk '/^Version [0-9]+ -> [0-9]+:$/ {block=""} {block=block $0 "\n"} END {print block}'
    '';
    # Show installed packages
    ni = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | less";
  };

  # System maintenance
  system.autoUpgrade = {
    enable = true;
    flake = "${upgradeFlake}#${config.networking.hostName}";
    flags = [
      "-L"
    ];
    dates = "04:40";
    persistent = true;
    randomizedDelaySec = "45min";
  };
  # Allow nixos-upgrade to restart on failure (e.g. when laptop wakes up before network connection is set)
  systemd.services.nixos-upgrade = {
    preStart = "${pkgs.host}/bin/host firecat53.net"; # Check network connectivity
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "120";
    };
    unitConfig = {
      StartLimitIntervalSec = 600;
      StartLimitBurst = 2;
    };
    path = [ pkgs.host ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;
  environment.systemPackages = [ pkgs.nixfmt-tree ];
}
