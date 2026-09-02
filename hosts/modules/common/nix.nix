{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  user = "firecat53";
  upgradeFlake = "git+https://git.firecat53.me/firecat53/nixos.git?ref=main";

  inherit (import ./ssh-keys.nix) hostKeys;
  hostName = config.networking.hostName;

  # The homeserver serves its own store; every host it authorizes pulls from
  # it. Keyed off hostKeys because that is what nix-cache.nix authorizes: the
  # install-media targets have no host key there, so for them the substituter
  # could only fail auth on every nix operation.
  useCache = hostName != "homeserver" && hostKeys ? ${hostName};
  # The VPS reaches it over wireguard, the rest over the LAN.
  cacheHost = if config.isRemote then "10.200.200.6" else "192.168.200.101";
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

    # The homeserver's store as a substituter, preferred over cache.nixos.org
    # (priority below its 40). Its flake-lock-update gate builds every host's
    # toplevel nightly, so an upgrade mostly comes off the LAN. It serves only
    # what it already has — there is no pull-through, so anything it lacks is
    # fetched straight from the CDN. Unreachable is non-fatal: nix warns and
    # falls through.
    extra-substituters = lib.mkIf useCache [
      "ssh://nix-ssh@${cacheHost}?ssh-key=/etc/ssh/ssh_host_ed25519_key&priority=10"
    ];
    extra-trusted-public-keys = lib.mkIf useCache [
      "homeserver-cache-1:17mNIhyXn4afM9gcIAguyXnd+AkE96mc3dAlloUb8X0="
    ];
  };

  # nix-daemon does the ssh, so this cannot live in a shell profile. Without
  # it an unreachable homeserver costs the OS TCP timeout (~2m13s) on every
  # nix invocation instead of 3s — which is what the roaming laptop hits.
  systemd.services.nix-daemon.environment.NIX_SSHOPTS = lib.mkIf useCache "-o ConnectTimeout=3";

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
