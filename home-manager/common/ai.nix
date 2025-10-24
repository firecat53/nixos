{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.code-cursor
    pkgs.unstable.claude-code
  ];
}
