{
  description = "System configurations";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/?shallow=1&ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";

    cursor.url = "github:omarcresp/cursor-flake/main";

    # Personal project flakes and secrets

    bwm.url = "github:firecat53/bitwarden-menu";
    bwm.inputs.nixpkgs.follows = "nixpkgs";

    keepmenu.url = "github:firecat53/keepmenu";
    keepmenu.inputs.nixpkgs.follows = "nixpkgs";

    todocalmenu.url = "github:firecat53/todocalmenu";
    todocalmenu.inputs.nixpkgs.follows = "nixpkgs";

    urlscan.url = "github:firecat53/urlscan";
    urlscan.inputs.nixpkgs.follows = "nixpkgs";

    my-secrets.url = "/home/firecat53/nixos/nixos-secrets";
    my-secrets.flake = false;

    neovim.url = "github:firecat53/nix-neovim";
    neovim.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = inputs@{
    self,
    catppuccin,
    disko,
    home-manager,
    nixpkgs,
    nixpkgs-unstable,
    sops-nix,
    ...
  }: let
  inherit (self) outputs;
    # Helper function to create a nixos system configuration
    # Usage:
    #   Default x86_64:  mkSystem { host = "hostname"; };
    #   Custom system:   mkSystem { host = "hostname"; system = "aarch64-linux"; };
  mkSystem = { host, system ? "x86_64-linux"}:
    nixpkgs.lib.nixosSystem {
      system = system;
      specialArgs = {
        inherit inputs outputs;
      };
      modules = [
        ./hosts/${host}/configuration.nix
      ];
    };
  in {
    nixosConfigurations = {
      backup = mkSystem { host = "backup";};
      homeserver = mkSystem { host = "homeserver"; };
      laptop = mkSystem { host = "laptop"; };
      office = mkSystem { host = "office"; };
      vps = mkSystem { host = "vps"; };
      minimal = mkSystem { host = "minimal"; };
      base-btrfs = mkSystem { host = "base-btrfs"; };
      base-zfs = mkSystem { host = "base-zfs"; };
    };
  }; 
}
