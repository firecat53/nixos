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
    python3
    ripgrep
    rsync
    screen
    tmux
    wget
    wireguard-tools
    unstable.yazi
  ];
}
