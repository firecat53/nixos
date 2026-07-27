# Nightly flake input update, pushed to forgejo `main`, which every host then
# builds at its 04:40 nixos-upgrade. Runs on the homeserver because it's always
# on. Works from its own clone so it doesn't touch anyone's working tree.
{ pkgs, ... }:
let
  user = "firecat53";
  stateDir = "flake-lock-update";
  repo = "/var/lib/${stateDir}/nixos";

  updateScript = pkgs.writeShellScript "flake-lock-update" ''
    set -euo pipefail

    if [ ! -e ${repo}/.git ]; then
      git clone forgejo:firecat53/nixos.git ${repo}
    fi

    # Discard anything left over from a run that died mid-way.
    git -C ${repo} fetch origin main
    git -C ${repo} checkout --force -B main FETCH_HEAD

    nix flake update --flake ${repo} --commit-lock-file
    git -C ${repo} push origin main
  '';
in
{
  systemd.services.flake-lock-update = {
    preStart = "${pkgs.host}/bin/host firecat53.net"; # Check network connectivity
    unitConfig = {
      Description = "Update flake.lock and commit to main";
      StartLimitIntervalSec = 600;
      StartLimitBurst = 2;
    };
    serviceConfig = {
      ExecStart = "${updateScript}";
      Restart = "on-failure";
      RestartSec = "120";
      StateDirectory = stateDir;
      Type = "oneshot";
      User = user;
    };
    # Signing config goes via GIT_CONFIG_* because nix runs `git commit`
    # internally for --commit-lock-file, so -c flags can't reach it.
    environment = {
      GIT_AUTHOR_NAME = "flake-lock-update";
      GIT_AUTHOR_EMAIL = "tech@firecat53.net";
      GIT_COMMITTER_NAME = "flake-lock-update";
      GIT_COMMITTER_EMAIL = "tech@firecat53.net";
      GIT_CONFIG_COUNT = "3";
      GIT_CONFIG_KEY_0 = "gpg.format";
      GIT_CONFIG_VALUE_0 = "ssh";
      GIT_CONFIG_KEY_1 = "user.signingkey";
      GIT_CONFIG_VALUE_1 = "/home/${user}/.config/sops-nix/secrets/signing-key";
      GIT_CONFIG_KEY_2 = "commit.gpgsign";
      GIT_CONFIG_VALUE_2 = "true";
    };
    path = [
      pkgs.nix
      pkgs.git
      pkgs.host
      pkgs.openssh # git push over the forgejo: ssh alias
    ];
  };
  systemd.timers.flake-lock-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };
}
