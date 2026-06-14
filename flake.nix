{
  description = "System configurations";

  inputs = {
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix/release-26.05";

    # Personal project flakes and secrets

    bwm.url = "github:firecat53/bitwarden-menu";
    bwm.inputs.nixpkgs.follows = "nixpkgs";

    keepmenu.url = "github:firecat53/keepmenu";
    keepmenu.inputs.nixpkgs.follows = "nixpkgs";

    todocalmenu.url = "github:firecat53/todocalmenu";
    todocalmenu.inputs.nixpkgs.follows = "nixpkgs";

    urlscan.url = "github:firecat53/urlscan";
    urlscan.inputs.nixpkgs.follows = "nixpkgs";

    watson-dmenu.url = "github:firecat53/watson-dmenu";
    watson-dmenu.inputs.nixpkgs.follows = "nixpkgs";

    my-secrets.url = "/home/firecat53/nixos/nixos-secrets";
    my-secrets.flake = false;

    neovim.url = "git+https://git.firecat53.me/firecat53/nix-neovim.git";
    neovim.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      catppuccin,
      disko,
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      ...
    }:
    let
      inherit (self) outputs;
      # Helper function to create a nixos system configuration
      # Usage:
      #   Default x86_64:  mkSystem { host = "hostname"; };
      #   Custom system:   mkSystem { host = "hostname"; system = "aarch64-linux"; };
      mkSystem =
        {
          host,
          system ? "x86_64-linux",
        }:
        nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/${host}/configuration.nix
          ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
    in
    {
      nixosConfigurations = {
        backup = mkSystem { host = "backup"; };
        homeserver = mkSystem { host = "homeserver"; };
        laptop = mkSystem { host = "laptop"; };
        office = mkSystem { host = "office"; };
        vps = mkSystem { host = "vps"; };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
