# Sabnzbd
{
  config,
  lib,
  ...
}:
{
  services.sabnzbd = {
    enable = true;
    configFile = null; # manage the ini through `settings` instead of the legacy file
    allowConfigWrite = true;
    user = "firecat53";
    group = "users";
    settings.misc.port = 8090;
  };
  systemd.services.sabnzbd.serviceConfig = {
    # Upstream daemonizes with -d; run in the foreground so logs reach the journal.
    Type = lib.mkForce "simple";
    ExecStart = lib.mkForce "${lib.getExe config.services.sabnzbd.package} -f /var/lib/${config.services.sabnzbd.stateDir}/sabnzbd.ini";
    StateDirectoryMode = "0700";
  };
  # nixpkgs' launcher forks python instead of exec'ing it, so the unit's MainPID
  # is a leftover bash parent. systemd then SIGTERMs bash *and* python, and the
  # second signal re-enters sabnzbd's shutdown handler and deadlocks it until the
  # 90s stop timeout SIGKILLs the lot. exec'ing leaves a single process, which
  # shuts down in ~0.4s. --replace-fail so this breaks loudly once nixpkgs fixes it.
  nixpkgs.overlays = [
    (final: prev: {
      sabnzbd = prev.sabnzbd.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/bin/.sabnzbd-wrapped \
            --replace-fail ' $*' ' "$@"'
          sed -i '1s|^|exec |' $out/bin/.sabnzbd-wrapped
        '';
      });
    })
  ];
  # Traefik routers/service generated from the registry (sabnzbd entry) by lan-proxy.nix.
}
