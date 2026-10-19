# AudioMuse-AI: sonic analysis / playlist generation for Jellyfin.
# Upstream image (pinned tag) + the native postgres cluster over its socket.
{ config, lib, ... }:
let
  version = "3.6.4";
  uid = 20002;
  gid = 20002;
  dataDir = "/var/lib/audiomuse";
  container = role: {
    image = "ghcr.io/neptunehub/audiomuse-ai:${version}";
    autoStart = true;
    # Peer auth: postgres sees this host uid on the socket, which maps to the
    # audiomuse role.
    user = "${toString uid}:${toString gid}";
    environment = {
      SERVICE_TYPE = role;
      POSTGRES_HOST = "/run/postgresql";
      POSTGRES_USER = "audiomuse";
      POSTGRES_DB = "audiomuse";
      # ivf_cache, plugins and tls live under here; the image's own /app
      # paths are root-owned.
      APP_DATA_DIR = "/data";
      TEMP_DIR = "/data/temp_audio";
      HOME = "/data";
      TZ = config.time.timeZone;
    };
    volumes = [
      "/run/postgresql:/run/postgresql"
      "${dataDir}/${role}:/data"
    ];
    extraOptions = [
      "--cap-drop=all"
      "--init=true"
      "--security-opt=no-new-privileges"
    ];
  };
in
{
  users.users.audiomuse = {
    inherit uid;
    isSystemUser = true;
    group = "audiomuse";
  };
  users.groups.audiomuse.gid = gid;

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 audiomuse audiomuse -"
    "d ${dataDir}/flask 0750 audiomuse audiomuse -"
    "d ${dataDir}/worker 0750 audiomuse audiomuse -"
  ];

  services.postgresql = {
    ensureDatabases = [ "audiomuse" ];
    ensureUsers = [
      {
        name = "audiomuse";
        ensureDBOwnership = true;
      }
    ];
  };

  virtualisation.oci-containers.containers = {
    audiomuse-flask = container "flask" // {
      ports = [ "127.0.0.1:8010:8000" ];
    };
    audiomuse-worker = container "worker";
  };

  systemd.services = lib.genAttrs [ "podman-audiomuse-flask" "podman-audiomuse-worker" ] (_: {
    requires = [ "postgresql-setup.service" ];
    after = [ "postgresql-setup.service" ];
  });

  # Traefik routers/service generated from the registry (audiomuse entry) by lan-proxy.nix.
}
