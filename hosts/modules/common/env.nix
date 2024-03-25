{
  # Systemwide ENV variables
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  ## Add ~/.local/bin to $PATH
  environment.localBinInPath = true;

  ## Show installed packages
  environment.shellAliases = {
    ni = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | less";
  };
}
