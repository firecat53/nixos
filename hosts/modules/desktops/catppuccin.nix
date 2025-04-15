{
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.catppuccin
  ];
}
