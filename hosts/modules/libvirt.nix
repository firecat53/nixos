{
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
  };
}
