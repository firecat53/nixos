{
  config,
  pkgs,
  ...
}:
let
  wikiDir = "${config.home.homeDirectory}/docs/family/scott/wiki";
  keyPath = "${config.home.homeDirectory}/.ssh/wiki-ssh";
in
{
  sops.secrets.wiki-ssh = {
    path = keyPath;
    mode = "0400";
  };

  # Ensure .stignore in place for the main wiki repo
  home.file."docs/.stignore".text = ''
    .git
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."forgejo-wiki" = {
      extraOptions = {
        PreferredAuthentications = "publickey";
        IdentitiesOnly = "yes";
      };
      hostname = "git.firecat53.me";
      identityFile = keyPath;
      port = 2222;
      user = "forgejo";
    };
  };

  systemd.user.services.wiki-sync = {
    Unit = {
      Description = "Sync wiki working tree to forgejo";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "wiki-sync" ''
        set -eu
        export PATH=${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.coreutils}/bin:$PATH
        cd ${wikiDir}
        git fetch --quiet origin
        git add -A
        if ! git diff --cached --quiet; then
          git -c commit.gpgsign=false \
              commit -m "auto: $(date -Iseconds)" --quiet
        fi
        git pull --rebase --autostash --quiet
        git push --quiet
      ''}";
    };
  };

  systemd.user.timers.wiki-sync = {
    Unit.Description = "Periodic wiki sync";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
      RandomizedDelaySec = "30s";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
