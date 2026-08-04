{
  config,
  lib,
  pkgs,
  ...
}:
let
  wikiDir = "${config.home.homeDirectory}/docs/family/scott/wiki";
in
{
  sops.secrets.wiki-ssh = { };
  sops.secrets.signing-key = { };

  # Keep the wiki repo's git dir out of syncthing. Written as a real file, not
  # home.file: syncthing opens .stignore with O_NOFOLLOW and errors out on a
  # store symlink.
  home.activation.docsStignore = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run install -Dm644 ${pkgs.writeText "docs-stignore" "/family/scott/wiki/.git\n"} \
      "${config.home.homeDirectory}/docs/.stignore"
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."forgejo-wiki" = {
      PreferredAuthentications = "publickey";
      IdentitiesOnly = "yes";
      HostName = "git.firecat53.me";
      IdentityFile = config.sops.secrets.wiki-ssh.path;
      Port = 2222;
      User = "forgejo";
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
          git -c gpg.format=ssh \
              -c user.signingkey=${config.sops.secrets.signing-key.path} \
              -c commit.gpgsign=true \
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
