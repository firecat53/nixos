# Nextcloud
{
  config,
  lib,
  pkgs,
  sops,
  ...
}:{
  sops.secrets.nextcloud-admin-password = {
    mode = "0440";
    owner = config.users.users.nextcloud.name;
    group = config.users.users.nextcloud.group;
  };
  users.users.nextcloud.extraGroups = ["render" "users"];
 
  environment.systemPackages = with pkgs; [
    nodejs_18  # required for Recognize
    ffmpeg  # required for Memories
  ];
  # Allow using /dev/dri for Memories
  systemd.services.phpfpm-nextcloud.serviceConfig = {
    PrivateDevices = lib.mkForce false;
  };

  services.nginx.virtualHosts."nc.firecat53.net".listen = [ { addr = "127.0.0.1"; port = 8180; } ];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "nc.firecat53.net";
    database.createLocally = true;
    configureRedis = true;
    appstoreEnable = true;
    config = {
      adminuser = "firecat53";
      adminpassFile = "${config.sops.secrets.nextcloud-admin-password.path}";
      dbtype = "mysql";
      defaultPhoneRegion = "US";
      trustedProxies = ["127.0.0.1"];
    };
    extraOptions = {
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
      mysql.utf8mb4 = true;
      memories.exiftool = "${lib.getExe pkgs.exiftool}";
      memories.vod.ffmpeg = "${lib.getExe pkgs.ffmpeg-headless}";
      memories.vod.ffprobe = "${pkgs.ffmpeg-headless}/bin/ffprobe";
      preview_ffmpeg_path = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
    };
    maxUploadSize = "10G"; # also sets post_max_size and memory_limit
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
    };
  };

  services.traefik.dynamicConfigOptions.http.routers.nextcloud = {
    rule = "Host(`nc.firecat53.net`)";
    service = "nextcloud";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.nextcloud = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8180";
        }
      ];
    };
  };

  systemd.timers."nextcloud-files-update" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
      Unit = "nextcloud-files-update.service";
    };
  };
  systemd.services."nextcloud-files-update" = {
    bindsTo = ["mysql.service" "phpfpm-nextcloud.service"];
    after = ["mysql.service" "phpfpm-nextcloud.service"];
    script = ''
      ${config.services.nextcloud.occ}/bin/nextcloud-occ files:scan -q --all
      ${config.services.nextcloud.occ}/bin/nextcloud-occ preview:pre-generate
    '';
    serviceConfig = {
      User = "nextcloud";
    };
    path = ["config.services.nextcloud" pkgs.perl];
  };
  systemd.services."nextcloud-cron" = {
    path = [pkgs.perl];
  };
}
