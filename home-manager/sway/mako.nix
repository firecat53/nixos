{
  pkgs,
  ...
}:
{
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-center";
      font = "Sauce Code Pro 14";
    };
  };
  home.packages = [ pkgs.libnotify ];
}
