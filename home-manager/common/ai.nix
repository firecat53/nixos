{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.unstable.claude-code
  ];
}
