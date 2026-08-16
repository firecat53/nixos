{
  description = "System configurations";

  inputs = {
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix/release-26.05";

    # Personal project flakes and secrets

    # Dashboard web assets; not a flake (its nix/ dir is the Pi kiosk image)
    bfd-apparatus.url = "git+https://git.firecat53.me/firecat53/BFD-apparatus.git";
    bfd-apparatus.flake = false;

    bwm.url = "github:firecat53/bitwarden-menu";
    bwm.inputs.nixpkgs.follows = "nixpkgs";

    crewsense.url = "git+https://git.firecat53.me/firecat53/crewsense.git";
    crewsense.inputs.nixpkgs.follows = "nixpkgs";

    keepmenu.url = "github:firecat53/keepmenu";
    keepmenu.inputs.nixpkgs.follows = "nixpkgs";

    memories.url = "git+https://git.firecat53.me/firecat53/memories.git";
    memories.inputs.nixpkgs.follows = "nixpkgs";

    todocalmenu.url = "github:firecat53/todocalmenu";
    todocalmenu.inputs.nixpkgs.follows = "nixpkgs";

    urlscan.url = "github:firecat53/urlscan";
    urlscan.inputs.nixpkgs.follows = "nixpkgs";

    watson-dmenu.url = "github:firecat53/watson-dmenu";
    watson-dmenu.inputs.nixpkgs.follows = "nixpkgs";

    # Private repo; ssh alias and deploy key in common/sshd.nix.
    my-secrets.url = "git+ssh://forgejo/firecat53/nixos-secrets";
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
        installer = mkSystem { host = "installer/iso"; };
        laptop = mkSystem { host = "laptop"; };
        # Stage-1 install target; regenerate its hardware-configuration.nix first.
        minimal = mkSystem { host = "installer/minimal"; };
        office = mkSystem { host = "office"; };
        vps = mkSystem { host = "vps"; };
      };

      # Rescue/installer ISO; built monthly on the homeserver.
      packages.x86_64-linux.installer-iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
