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
  ];
}
