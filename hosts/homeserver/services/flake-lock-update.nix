# Nightly flake input update, committed to the local `main` branch.
#
# flake.lock is committed to git, so the server auto-upgrades (which build
# from ?ref=main) only ever see the locked inputs recorded on main. This
# service provides the rolling-update behavior: it runs `nix flake update
# --commit-lock-file` in a throwaway git worktree of main, advancing main by
# one lock-bump commit. Syncthing syncs .git to every other host, so the
# other servers pick up the new lock at their 04:40 nixos-upgrade run.
#
# Runs only on the homeserver (always on, unlike the laptop). It fires at
# 04:00 so the commit has synced everywhere before the 04:40 upgrades start.
# Desktops build from the working tree (usually the dev branch) and pick up
# lock bumps when dev is rebased onto main.
#
# main is also pushed to forgejo nightly: syncthing replicates disasters as
# readily as commits, so the forgejo repo (and its GitHub mirror) is the only
# copy outside the syncthing domain — and the clone source for rebuilding
# from scratch. dev is pushed manually.
{ pkgs, ... }:
let
  user = "firecat53";
  repo = "/home/${user}/nixos/nixos";

  updateScript = pkgs.writeShellScript "flake-lock-update" ''
    set -euo pipefail

    # The checked-out branch here follows whatever was last synced (HEAD lives
    # in the syncthing-synced .git), and git refuses to check out a branch
    # that another worktree already has. So update main in place when it is
    # checked out, and via a throwaway worktree otherwise.
    if [ "$(git -C ${repo} symbolic-ref --short -q HEAD || true)" = "main" ]; then
      nix flake update --flake ${repo} --commit-lock-file
    else
      worktree="$(mktemp -d)/main"
      cleanup() {
        git -C ${repo} worktree remove --force "$worktree" 2>/dev/null || true
        git -C ${repo} worktree prune
        rm -rf "$(dirname "$worktree")"
      }
      trap cleanup EXIT

      git -C ${repo} worktree add "$worktree" main
      nix flake update --flake "$worktree" --commit-lock-file
    fi

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
      Type = "oneshot";
      User = user;
    };
    # Identity for the automated lock-bump commits
    environment = {
      GIT_AUTHOR_NAME = "flake-lock-update";
      GIT_AUTHOR_EMAIL = "tech@firecat53.net";
      GIT_COMMITTER_NAME = "flake-lock-update";
      GIT_COMMITTER_EMAIL = "tech@firecat53.net";
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
