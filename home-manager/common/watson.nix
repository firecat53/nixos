{
  config,
  ...
}:
{
  programs.watson = {
    enable = true;
    enableBashIntegration = true;
  };
  home.sessionVariables = {
    WATSON_DIR = "${config.home.homeDirectory}/docs/family/scott/src/watson";
  };
}
