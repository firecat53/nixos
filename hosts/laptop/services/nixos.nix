{
  pkgs,
  ...
}: let
  user = "firecat53";
  flakePath = "/home/${user}/nixos/nixos";
in {
  ## Update flake inputs daily
  systemd.services = {
    flake-update = {
      preStart = "${pkgs.host}/bin/host firecat53.net";  # Check network connectivity
      unitConfig = {
        Description = "Update flake inputs";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      serviceConfig = {
        ExecStart = "${pkgs.nix}/bin/nix flake update --commit-lock-file ${flakePath}";
        Restart = "on-failure";
        RestartSec = "30";
        Type = "oneshot"; # Ensure that it finishes before starting nixos-upgrade
        User = "${user}";
      };
      before = ["nixos-upgrade.service"];
      path = [pkgs.nix pkgs.git pkgs.host];
    };
  };
}
