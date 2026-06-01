{
  pkgs,
  ...
}:
let
  catppuccin-theme = pkgs.catppuccin-sddm.override {
    flavor = "mocha";
    accent = "sapphire";
    font = "Maple Mono NF";
    fontSize = "17";
    loginBackground = true;
  };
in
{
  services.displayManager.sddm = {
    enable = true;
    enableHidpi = true;
    package = pkgs.kdePackages.sddm;
    theme = "${catppuccin-theme}/share/sddm/themes/catppuccin-mocha-sapphire";
    wayland.enable = false;
  };
}
