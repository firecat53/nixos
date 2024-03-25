{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  user = "firecat53";
  flakePath = "/home/${user}/nixos/nixos";
in {
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable git
  programs.git.enable = true;

  # Pin nixpkgs to local version for searches
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.registry.nixpkgs-stable.flake = inputs.nixpkgs-stable;

  # Allow unfree packages and pulling some packages from stable
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      stable = import inputs.nixpkgs-stable {
        config = config.nixpkgs.config;
        system = "x86_64-linux";
      };
      unstable = import inputs.nixpkgs {
        config = config.nixpkgs.config;
        system = "x86_64-linux";
      };
    };
  };

  # Show nix updates
  environment.shellAliases = {
    nd = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
  };

  # System maintenance
  system.autoUpgrade = {
    enable = true;
    flake = "${flakePath}#${config.networking.hostName}";
    flags = [
      "-L"
    ];
    dates = "04:40";
    persistent = true;
    randomizedDelaySec = "45min";
  };
  # Allow nixos-upgrade to restart on failure (e.g. when laptop wakes up before network connection is set)
  systemd.services.nixos-upgrade = {
    preStart = "${pkgs.host}/bin/host firecat53.net";  # Check network connectivity
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "120";
    };
    unitConfig = {
      StartLimitIntervalSec = 600;
      StartLimitBurst = 2;
    };
    after = ["flake-update.service"];
    wants = ["flake-update.service"];
    path = [pkgs.host];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;
}
