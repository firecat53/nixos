{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = "firecat53";
  ref =
    if
      builtins.elem config.networking.hostName [
        "office"
        "laptop"
      ]
    then
      "dev"
    else
      "main";
  flakePath = "/home/${user}/nixos/nixos?ref=${ref}";
  secretspath = builtins.toString inputs.my-secrets;
in
{
  # Set github access token for nixpkgs
  sops.secrets.nix_access_token = {
    sopsFile = "${secretspath}/common/secrets.yaml";
    owner = "firecat53";
  };
  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_access_token.path}
  '';

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
  programs.git.enable = true;

  # Add unstable to flake registry to use locally (e.g. `nix run nixpkgs-unstable#hatch`)
  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;

  # Allow unfree packages and pulling some packages from stable
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      stable = import inputs.nixpkgs {
        config = config.nixpkgs.config;
        system = "x86_64-linux";
      };
      unstable = import inputs.nixpkgs-unstable {
        config = config.nixpkgs.config;
        system = "x86_64-linux";
      };
    };
    permittedInsecurePackages = [
      "olm-3.2.16"
    ];
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
    preStart = "${pkgs.host}/bin/host firecat53.net"; # Check network connectivity
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "120";
    };
    unitConfig = {
      StartLimitIntervalSec = 600;
      StartLimitBurst = 2;
    };
    after = [ "flake-update.service" ];
    wants = [ "flake-update.service" ];
    path = [ pkgs.host ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  ## Show installed packages
  environment.shellAliases = {
    ni = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | less";
  };
  ## Update flake inputs daily
  systemd.services = {
    flake-update = {
      preStart = "${pkgs.host}/bin/host firecat53.net"; # Check network connectivity
      unitConfig = {
        Description = "Update flake inputs";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      serviceConfig = {
        ExecStart = "${pkgs.nix}/bin/nix flake update --flake ${flakePath}";
        Restart = "on-failure";
        RestartSec = "30";
        Type = "oneshot"; # Ensure that it finishes before starting nixos-upgrade
        User = "${user}";
      };
      before = [ "nixos-upgrade.service" ];
      path = [
        pkgs.nix
        pkgs.git
        pkgs.host
      ];
    };
  };
}
