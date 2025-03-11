{
  pkgs,
  ...
}:
{
  services.mako = {
    enable = true;
    anchor = "top-center";
    font = "Sauce Code Pro 14";
  };
  home.packages = [ pkgs.libnotify ];
}
