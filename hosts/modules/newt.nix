# Add the Newt wireguard tunnel utility for Pangolin
{
  config,
  inputs,
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
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/newt.nix"
  ];

  services.newt = {
    enable = true;
    package = pkgs.unstable.fosrl-newt;
    environmentFile = "${config.sops.secrets.newt-env.path}";
  };
}
