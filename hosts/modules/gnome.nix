{
  pkgs,
  ...
}:{
  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  ### Ensure system tray icons are visible
  environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
}
