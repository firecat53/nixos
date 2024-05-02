{
  pkgs,
  ...
}:{
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
    ranger
    ripgrep
    rsync
    screen
    tmux
    vim
    wget
    wireguard-tools
  ];
} 
