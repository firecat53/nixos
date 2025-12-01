{
  pkgs,
  ...
}:
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
  home.packages = [ pkgs.nix-search-tv ];
  programs.bash.shellAliases = {
    ns = "nix-search-tv print | fzf --exact --preview 'nix-search-tv preview {}' --scheme history";
  };
}
