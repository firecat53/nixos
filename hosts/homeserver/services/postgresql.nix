{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
  };

  # Postgres backup
  services.postgresqlBackup = {
    enable = true;
    location = "/var/backups/postgres";
    backupAll = true;
  };

  # From the NixOS manual
  # This creates upgrade-pg-cluster script to run as root when upgrading
  # postgres to a new major version.
  environment.systemPackages = [
    (
      let
        # TODO specify the postgresql package you'd like to upgrade to.
        # Do not forget to list the extensions you need.
        # Also update pg_upgrade command below with `--new-options "-c shared_preload_libraries='vchord.so'"`
        # if using Immich and vectorchord to ensure new version sees the extension.
        newPostgres = pkgs.postgresql_17.withPackages (pp: [
          pp.vectorchord
          pp.pgvector
        ]);
        cfg = config.services.postgresql;
      in
      pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
        export NEWBIN="${newPostgres}/bin"

        export OLDDATA="${cfg.dataDir}"
        export OLDBIN="${cfg.finalPackage}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" --data-checksums ${lib.escapeShellArgs cfg.initdbArgs}

        sudo -u postgres "$NEWBIN/pg_upgrade" \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
          --new-options "-c shared_preload_libraries='vchord.so'" \
          "$@"
      ''
    )
  ];
}
