{
  pkgs,
  ...
}:
{
  services.displayManager.sddm = {
    enable = true;
    enableHidpi = true;
    extraPackages = [ pkgs.catppuccin-sddm ];
    package = pkgs.kdePackages.sddm;
    theme = "catppuccin-mocha";
    wayland.enable = true;
  };
  environment.systemPackages = [
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      font = "DevjaVu Sans";
      fontSize = "17";
      loginBackground = true;
    })
  ];
}
