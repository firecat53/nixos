{
  # Grub Configuration without plymouth
  boot = {
    initrd.systemd.enable = true;
    loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
      };
    };
  };
}
