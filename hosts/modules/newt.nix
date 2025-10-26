# Add the Newt wireguard tunnel utility for Pangolin
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.newt-env = { };

  # TODO - remove when newt module hits stable
  disabledModules = [
    "services/networking/newt.nix"
  ];
  imports = [
    (import "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/newt.nix" {
      inherit config pkgs;
      lib = lib // {
        cli.toCommandLineShellGNU = lib.cli.toGNUCommandLineShell;  # Override to use old version
      };
    })

  ];

  services.newt = {
    enable = true;
    package = pkgs.unstable.fosrl-newt;
    environmentFile = "${config.sops.secrets.newt-env.path}";
  };
}
