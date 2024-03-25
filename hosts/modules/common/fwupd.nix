{
  # Firmware updates - fwupd
  services.fwupd.enable = true;
  # Allow fwupd-refresh to restart if failed (after resume)
  systemd.services.fwupd-refresh = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "20";
    };
    unitConfig = {
      StartLimitIntervalSec = 100;
      StartLimitBurst = 5;
    };
  };
}
