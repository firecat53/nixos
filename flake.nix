{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Personal project flakes and secrets

    bwm.url = "github:firecat53/bitwarden-menu";
    bwm.inputs.nixpkgs.follows = "nixpkgs";

    keepmenu.url = "github:firecat53/keepmenu";
    keepmenu.inputs.nixpkgs.follows = "nixpkgs";

    urlscan.url = "github:firecat53/urlscan";
    urlscan.inputs.nixpkgs.follows = "nixpkgs";

    my-secrets.url = "/home/firecat53/nixos/nixos-secrets";
    my-secrets.flake = false;
  };

  outputs = inputs@{
    self,
    disko,
    nixpkgs,
    nixpkgs-stable,
    sops-nix,
    home-manager,
    ...
  }: let
    inherit (self) outputs;
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      backup = nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/backup/configuration.nix
        ];
      };
      homeserver = nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/homeserver/configuration.nix
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/laptop/configuration.nix
        ];
      };
      office = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/office/configuration.nix
        ];
      };
      vps  = nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/vps/configuration.nix
        ];
      };
    };
  }; 
}
