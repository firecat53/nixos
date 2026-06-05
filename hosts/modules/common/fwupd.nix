{
  config,
  lib,
  ...
}:
{
  # Firmware updates - fwupd
  services.fwupd = lib.mkIf (!config.isVirtual) {
    enable = false; # TODO - enable when https://github.com/NixOS/nixpkgs/pull/526476/changes merged
  };
  # Allow fwupd-refresh to restart if failed (after resume)
  systemd.services.fwupd-refresh = lib.mkIf (!config.isVirtual) {
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
