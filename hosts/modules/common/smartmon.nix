{
  ### Smartmon
  services.smartd.enable = true;
  services.smartd.defaults.monitored = "-a -o on -S on -s (S/../.././01|L/../../6/02) -m root";
}
