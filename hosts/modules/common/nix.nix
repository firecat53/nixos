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
  programs.git = {
    enable = true;
    config = {
      safe."directory" = "/home/${user}/nixos/nixos";
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
        system = "x86_64-linux";
      };
      unstable = import inputs.nixpkgs-unstable {
        config = config.nixpkgs.config;
        system = "x86_64-linux";
      };
    };
    permittedInsecurePackages = [
      "olm-3.2.16" # Required by gomuks
      "python3.12-ecdsa-0.19.1" # Required by electrum
    ];
  };

  # Show nix updates
  environment.shellAliases = {
    nd = ''nix profile diff-closures --profile /nix/var/nix/profiles/system |
      awk '/^Version [0-9]+ -> [0-9]+:$/ {block=""} {block=block $0 "\n"} END {print block}'
    '';
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

  ## Show installed packages
  environment.shellAliases = {
    ni = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | less";
  };
}
