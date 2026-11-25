# Generic desktop: the generic server plus COSMIC, with sway as a second
# session in the greeter.
#
#   sudo disko-install --flake .#generic-desktop --disk main /dev/<disk>
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # cosmic-greeter copies DesktopNames into XDG_CURRENT_DESKTOP unconverted
  # and greetd runs the command through a shell, so sway's stock
  # "DesktopNames=sway;wlroots" splits the command at the ';'.
  swaySession =
    pkgs.writeTextDir "share/wayland-sessions/sway.desktop" ''
      [Desktop Entry]
      Name=Sway
      Comment=An i3-compatible Wayland compositor
      Exec=${lib.getExe config.programs.sway.package}
      Type=Application
      DesktopNames=sway
    ''
    // {
      providedSessions = [ "sway" ];
    };
in
{
  imports = [ ./configuration.nix ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  programs.sway.enable = true;
  programs.firefox.enable = true;

  # Replaces the sway package's session; see swaySession above.
  services.displayManager.sessionPackages = lib.mkForce [
    pkgs.cosmic-session
    swaySession
  ];

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
