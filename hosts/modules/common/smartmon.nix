{
  config,
  lib,
  ...
}:
{
  ### Smartmon
  services.smartd = lib.mkIf (!config.isVirtual) {
    enable = true;
    defaults.monitored = "-a -o on -S on -s (S/../.././01|L/../../6/02) -m root";
  };
}
