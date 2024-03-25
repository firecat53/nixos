{
  pkgs,
  ...
}:{
  home.packages = with pkgs; [
    khal
    khard
    vdirsyncer # TODO configure services
  ];

  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/15";
  };
  # Allow vdirsyncer to restart on failure (after resume from suspend)
  systemd.user.services.vdirsyncer = {
    Service = {
      Restart = "on-failure";
      RestartSec = "20";
    };
    Unit = {
      StartLimitIntervalSec = 100;
      StartLimitBurst = 5;
    };
  };
}
