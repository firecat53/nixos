{
  pkgs,
  ...
}:{
  services.displayManager = {
    sddm.enable = true;
    sddm.package = pkgs.kdePackages.sddm;
  };
}
