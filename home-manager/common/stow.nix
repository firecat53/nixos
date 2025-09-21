{
  config,
  ...
}:
{
  home.file.".stowrc" = {
    text = ''
      --dir=${config.home.homeDirectory}/docs/family/scott/src/dotfiles
      --target=${config.home.homeDirectory}
      --dotfiles
    '';
  };
}
