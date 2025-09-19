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
    curl
    git
    jq
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
