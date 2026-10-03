{ config, ... }:
{
  # Ctrl-G opens navi in bash
  programs.navi = {
    enable = true;
    enableBashIntegration = true;
    settings.cheats.paths = [ "${config.home.homeDirectory}/docs/family/scott/src/state/navi" ];
  };
}
