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
      ""
    else
      "?ref=main";
  flakePath = "/home/${user}/nixos/nixos${ref}";
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
      safe."directory" = [
        "/home/${user}/nixos/nixos"
        "/home/${user}/nixos/nixos-secrets"
      ];
    };
  };

  # Add unstable to flake registry to use locally (e.g. `nix run nixpkgs-unstable#hatch`)
  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;

  # Allow unfree packages and pulling some packages from stable
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      stable = import inputs.nixpkgs {
        config = config.nixpkgs.config;
        system = pkgs.stdenv.hostPlatform.system;
      };
      unstable = import inputs.nixpkgs-unstable {
        config = config.nixpkgs.config;
        system = pkgs.stdenv.hostPlatform.system;
      };
    };
    permittedInsecurePackages = [
      "olm-3.2.16" # Required by gomuks
    ];
  };

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
