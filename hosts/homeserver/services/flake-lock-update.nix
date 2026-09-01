# Nightly flake input update, pushed to forgejo `main`, which every host then
# builds at its 04:40 nixos-upgrade. Runs on the homeserver because it's always
# on. Works from its own clone so it doesn't touch anyone's working tree.
#
# Every host's toplevel is built before the push, so a broken input can't reach
# all five at once. A failure leaves `main` on the last good lock and fails the
# unit, which prometheus alerts on.
{ pkgs, ... }:
let
  user = "firecat53";
  stateDir = "flake-lock-update";
  repo = "/var/lib/${stateDir}/nixos";
  resultPrefix = "/var/lib/${stateDir}/result-";

  updateScript = pkgs.writeShellScript "flake-lock-update" ''
    set -euo pipefail

    if [ ! -e ${repo}/.git ]; then
      git clone forgejo:firecat53/nixos.git ${repo}
    fi

    # Discard anything left over from a run that died mid-way.
    git -C ${repo} fetch origin main
    git -C ${repo} checkout --force -B main FETCH_HEAD

    nix flake update --flake ${repo} --commit-lock-file

    # Read the host list from the clone, so a host added to the flake is gated
    # without touching this file. The install-media targets are dropped here and
    # gated by evaluation just below.
    hosts=$(nix eval --raw ${repo}#nixosConfigurations --apply \
      'cfgs: builtins.concatStringsSep " " (builtins.filter (h: h != "installer" && h != "minimal") (builtins.attrNames cfgs))')

    # Evaluate the minimal config. 
    nix eval --raw ${repo}#packages.x86_64-linux.installer-iso.drvPath >/dev/null
    # minimal's placeholder hardware-configuration.nix has no root filesystem,
    # so one is supplied here to get its toplevel past the assertion.
    nix eval --raw ${repo}#nixosConfigurations.minimal --apply \
      'cfg: (cfg.extendModules { modules = [ { fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; }; } ]; }).config.system.build.toplevel.drvPath' >/dev/null

    # --out-link roots the current toplevel per host, so the weekly gc reclaims
    # only the superseded ones instead of the whole desktop closure.
    for host in $hosts; do
      nix build ${repo}#nixosConfigurations."$host".config.system.build.toplevel \
        --out-link ${resultPrefix}"$host"
    done

    # Drop roots for hosts no longer in the flake, which would otherwise pin a
    # stale closure forever.
    for link in ${resultPrefix}*; do
      [ -e "$link" ] || [ -L "$link" ] || continue # also catches the unmatched glob
      host=''${link#${resultPrefix}}
      case " $hosts " in
        *" $host "*) ;;
        *) rm -f "$link" ;;
      esac
    done

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
