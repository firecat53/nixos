{
  config,
  ...
}:
let
  diunConfig = config.environment.etc."diun/diun.yml".source;
  desktopImages = config.environment.etc."diun/images/desktops.yml".source;
  homeserverImages = config.environment.etc."diun/images/homeserver.yml".source;
  pangolinImages = config.environment.etc."diun/images/pangolin.yml".source;
in
{
  virtualisation.oci-containers.containers.diun = {
    image = "crazymax/diun:latest";
    autoStart = true;
    user = "nobody:nogroup";
    volumes = [
      "${diunConfig}:/diun.yml:ro"
      "${desktopImages}:/images/desktops.yml:ro"
      "${homeserverImages}:/images/homeserver.yml:ro"
      "${pangolinImages}:/images/pangolin.yml:ro"
      "${config.sops.secrets.docker-hub-token.path}:/docker-hub-token:ro"
      "${config.sops.secrets.matrix-notifier-password.path}:/matrix-notifier-password:ro"
      "/var/lib/diun:/data"
    ];
    environment = {
      TZ = "America/Los_Angeles";
      LOG_LEVEL = "info";
    };
  };
  sops.secrets = {
    docker-hub-token = {
      owner = "nobody";
      group = "nogroup";
    };
    matrix-notifier-password = {
      owner = "nobody";
      group = "nogroup";
    };
  };
  environment.etc."diun/diun.yml".text = ''
    db:
      path: /data/diun.db

    watch:
      workers: 10
      schedule: "0 */6 * * *"  # Every 6 hours

    regopts:
      - name: "docker.io"
        selector: image
        username: "firecat53"
        passwordFile: "/docker-hub-token"

    providers:
      file:
        directory: /images/

    notif:
      matrix:
        homeserverURL: https://matrix.firecat53.net
        user: "@notifier:firecat53.net"
        passwordFile: "/matrix-notifier-password"
        roomID: "!KpLUPKbxnaqAQdTnqG:firecat53.net"
        msgType: notice
        templateBody: |
          Docker tag {{ .Entry.Image }} has been released.
  '';

  environment.etc."diun/images/pangolin.yml".text = ''
    - name: fosrl/pangolin
      watch_repo: true
      include_tags:
        - "^1\\."  # Only major version 1.x
      sort_tags: semver
      max_tags: 1

    - name: fosrl/gerbil
      watch_repo: true
      include_tags:
        - "^1\\."  # Only major version 1.x
      sort_tags: semver
      max_tags: 1
  '';
  environment.etc."diun/images/homeserver.yml".text = ''
    - name: crazymax/diun
      watch_repo: true
      include_tags:
        - "^4\\."  # Only major version 4.x
      sort_tags: semver
      max_tags: 1

    - name: ghcr.io/hargata/lubelogger:latest

    - name: frooodle/s-pdf:latest

    - name: docker.io/collabora/code

    - name: library/golang
      watch_repo: true
      sort_tags: reverse
      include_tags:
        - "^1-alpine3\\.2"  # Only major version 1-alpine3.2x
      max_tags: 1

    - name: library/alpine
      watch_repo: true
      sort_tags: semver
      include_tags:
        - "^3\\."  # Only major versions 3.x
      max_tags: 1
  '';
  environment.etc."diun/images/desktops.yml".text = ''
    - name: library/archlinux:latest

    - name: library/ubuntu:latest

    - name: library/alpine:latest
  '';
  # Create data directory
  systemd.tmpfiles.rules = [
    "d /var/lib/diun 0700 nobody nogroup -"
  ];
}
