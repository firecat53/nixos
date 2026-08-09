# Monthly rescue/installer ISO build. Outputs to /mnt/downloads/iso
#
# Works from its own clone so it never touches anyone's working tree.
{ pkgs, ... }:
let
  user = "firecat53";
  stateDir = "installer-iso";
  repo = "/var/lib/${stateDir}/nixos";
  outDir = "/mnt/downloads/iso";
  keep = 2; # builds to retain in outDir

  buildScript = pkgs.writeShellScript "installer-iso-build" ''
    set -euo pipefail

    if [ ! -e ${repo}/.git ]; then
      git clone forgejo:firecat53/nixos.git ${repo}
    fi

    # Discard anything left over from a run that died mid-way.
    git -C ${repo} fetch origin main
    git -C ${repo} checkout --force -B main FETCH_HEAD

    nix build ${repo}#packages.x86_64-linux.installer-iso \
      --out-link /var/lib/${stateDir}/result

    iso=$(find /var/lib/${stateDir}/result/iso -name '*.iso' -print -quit)
    if [ -z "$iso" ]; then
      echo "installer-iso: no .iso in build output" >&2
      exit 1
    fi

    # 0664 + the setgid/ACLs permissions.nix puts on /mnt/downloads means this
    # lands as firecat53:users with no explicit chown needed.
    install -m 0664 "$iso" ${outDir}/"$(basename "$iso")"
    echo "installer-iso: wrote ${outDir}/$(basename "$iso")"

    # Retain the newest ${toString keep}. Glob is deliberately narrow so this
    # can only ever remove images this service produced.
    ls -1t ${outDir}/nixos-installer-*.iso 2>/dev/null \
      | tail -n +${toString (keep + 1)} \
      | while read -r old; do
          echo "installer-iso: pruning $old"
          rm -f "$old"
        done
  '';
in
{
  systemd.services.installer-iso = {
    preStart = "${pkgs.host}/bin/host firecat53.net"; # Check network connectivity
    unitConfig = {
      Description = "Build the rescue/installer ISO";
      RequiresMountsFor = outDir;
      StartLimitIntervalSec = 86400;
      StartLimitBurst = 2;
    };
    serviceConfig = {
      ExecStart = "${buildScript}";
      Restart = "on-failure";
      RestartSec = "1h";
      StateDirectory = stateDir;
      Type = "oneshot";
      User = user;
      # Building an ISO is long and IO-heavy; stay out of the way of the
      # media services, but don't hang forever if something wedges.
      TimeoutStartSec = "4h";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
    path = [
      pkgs.nix
      pkgs.git
      pkgs.host
      pkgs.openssh # git clone over the forgejo: ssh alias
    ];
  };
  systemd.timers.installer-iso = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };
}
