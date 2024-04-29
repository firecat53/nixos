{
  pkgs,
  ...
}:{
  services.xserver.enable = true;

  # Fingerprint login
  #services.fprintd.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    nerdfonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "caps:escape";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    cups-pdf = {
      enable = true;
      instances.pdf.settings = {
        Out = "\${HOME}/.local/tmp";
      };
    };
  };

  # Enable sound.
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable flatpak support
  # See home-manager/bash.nix for exports/bin and $XDG_DATA_DIRS config
  services.flatpak.enable = true;

  # Allow /dev/uinput access for users (ydotool)
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="users", MODE="0660",  OPTIONS+="static_node=uinput"
  '';
}
