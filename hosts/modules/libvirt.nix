{
  pkgs,
  ...
}:{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
  };
}
