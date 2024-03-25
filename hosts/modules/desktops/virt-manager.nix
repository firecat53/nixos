{
  pkgs,
  ...
}:{
  virtualisation.spiceUSBRedirection.enable = true;
  programs.virt-manager.enable = true;
}
