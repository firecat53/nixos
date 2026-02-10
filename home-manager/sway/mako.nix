{
  pkgs,
  ...
}:
{
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-center";
      font = "Maple Mono NF 14";
    };
  };
  home.packages = [ pkgs.libnotify ];
}
