{
  description = "System configurations";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
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
  };

  outputs = inputs@{
    self,
    disko,
    nixpkgs,
    nixpkgs-unstable,
    sops-nix,
    home-manager,
    catppuccin,
    ...
  }: let
    inherit (self) outputs;
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      backup = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/backup/configuration.nix
        ];
      };
      homeserver = nixpkgs.lib.nixosSystem {
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
      vps  = nixpkgs.lib.nixosSystem {
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
