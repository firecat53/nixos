{
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    inputs.neovim.overlays.default
  ];
  environment.systemPackages = [
    pkgs.nvim-pkg
    pkgs.nixfmt-rfc-style
  ];
}
