{
  pkgs,
  ...
}:
{
  # General systemwide packages
  environment.systemPackages = with pkgs; [
    bottom
    curl
    dua
    fd
    git
    jq
    # So TERM=xterm-kitty works over ssh; ncurses ships no entry for it
    kitty.terminfo
    lf
    nix-tree
    pciutils
    python3
    ripgrep
    rsync
    screen
    tmux
    wget
    wireguard-tools
    usbutils
  ];
}
