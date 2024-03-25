{
  pkgs,
  ...
}:{
  # Power management
  powerManagement.powertop.enable = true;
  services.tlp.enable = true;

  systemd.services.setBatteryChargeLimit = {
    description = "Set battery charge limit to 75% when started and 96% when stopped";
    enable = true;
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tlp}/bin/tlp setcharge 75 80";
      ExecStop = "${pkgs.tlp}/bin/tlp setcharge 96 100";
    };
  };
}
