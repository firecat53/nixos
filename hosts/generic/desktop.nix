# Generic desktop: the generic server plus COSMIC, with sway as a second
# session in the greeter.
#
#   sudo disko-install --flake .#generic-desktop --disk main /dev/<disk>
{ pkgs, ... }:
{
  imports = [ ./configuration.nix ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  programs.sway.enable = true;
  programs.firefox.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Apps via COSMIC Store without touching nix
  services.flatpak.enable = true;
  services.printing.enable = true;
  # VM clipboard sharing and resize; inert on bare metal
  services.spice-vdagentd.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
