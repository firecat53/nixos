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
    unstable.neovim
    nix-tree
    python3
    ranger
    ripgrep
    rsync
    screen
    tmux
    wget
    wireguard-tools
  ];
} 
