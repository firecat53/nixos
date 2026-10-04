# CrowdSec for internet-facing hosts: parses sshd + Traefik access logs, pulls
# the community blocklist, and bans offenders in iptables (before the TLS
# handshake reaches Traefik). Private/wireguard ranges are whitelisted, so the
# VPS -> homeserver proxy hop can't get banned; so are the hosts' public IPs
# (the tunnel endpoints) and a few app-client false positives.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  traefikLog = "/var/log/traefik/access.log";
in
{
  services.crowdsec = {
    enable = true;
    autoUpdateService = true;
    hub = {
      collections = [
        "crowdsecurity/linux"
        "crowdsecurity/traefik"
        "crowdsecurity/http-cve"
      ];
      parsers = [ "crowdsecurity/whitelists" ];
    };
    localConfig = {
      parsers.s02Enrich = [
        {
          name = "firecat53/whitelists";
          description = "Our own hosts and known app-client false positives";
          whitelist = {
            reason = "own hosts / app clients";
            # Home and VPS public IPs: a ban on either drops the wireguard tunnel
            ip = [
              "50.46.34.102"
              "5.78.80.98"
            ];
            expression = [
              # Finamp fetches hundreds of /Items/<id> at once -> http-crawl-non_statics
              "evt.Meta.target_fqdn == 'jellyfin.firecat53.me' && evt.Meta.http_status matches '^[23]'"
              # Audiobookshelf 404s for every author without a photo -> http-probing
              "evt.Meta.target_fqdn == 'books.firecat53.me' && evt.Meta.http_status == '404' && evt.Meta.http_path matches '^/api/authors/[^/]+/image([?]|$)'"
            ];
          };
        }
      ];
      acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
        {
          filenames = [ traefikLog ];
          labels.type = "traefik";
        }
      ];
      # Per-IP scenarios miss scrapers that rotate through hundreds of IPs in
      # one provider (e.g. Tencent, ~1200 IPs/min). Count distinct IPs per ASN
      # and ban the offending IP's announced range instead. Fediverse servers
      # are excluded so a boosted post's link-preview stampede doesn't trip it.
      scenarios = [
        {
          type = "leaky";
          name = "firecat53/http-asn-distributed-crawl";
          description = "Many distinct IPs from one ASN hitting HTTP";
          filter = ''
            evt.Meta.log_type == 'http_access-log'
            && evt.Meta.ASNNumber not in ["", "0"]
            && not (evt.Meta.http_user_agent matches '(?i)(mastodon|akkoma|pleroma|misskey|sharkey|gotosocial|friendica|lemmy|pixelfed|peertube|synapse)')
          '';
          groupby = "evt.Meta.ASNNumber";
          distinct = "evt.Meta.source_ip";
          capacity = 50;
          leakspeed = "10s";
          blackhole = "1m";
          scope = {
            type = "Range";
            expression = "evt.Meta.SourceRange";
          };
          labels = {
            service = "http";
            behavior = "http:crawl";
            label = "Distributed crawl from one ASN";
            remediation = true;
          };
        }
      ];
    };
    settings = {
      general.api.server = {
        enable = true;
        listen_uri = "127.0.0.1:8095"; # 8080 is taken on both hosts
      };
      lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
    };
  };

  services.crowdsec-firewall-bouncer.enable = true;

  # Workarounds for the nixpkgs modules, all fixed by NixOS/nixpkgs#535319
  # (targeting 26.11, renames options) -- drop this block once it lands:
  # - crowdsec's setup runs `machine add` before `capi register`, and the
  #   former fails if the CAPI credentials file doesn't exist yet
  # - the bouncer-register unit runs bare cscli, which reads /etc/crowdsec/config.yaml
  # - bouncer-register lists crowdsec in its DynamicUser StateDirectory, which
  #   moves /var/lib/crowdsec under /var/lib/private where crowdsec can't reach it
  systemd.services.crowdsec-capi-creds = {
    before = [ "crowdsec.service" ];
    requiredBy = [ "crowdsec.service" ];
    serviceConfig.Type = "oneshot";
    script =
      let
        creds = config.services.crowdsec.settings.capi.credentialsFile;
      in
      ''
        install -d -o crowdsec -g crowdsec -m 0750 "$(dirname ${creds})"
        [ -e ${creds} ] || install -o crowdsec -g crowdsec -m 0600 /dev/null ${creds}
      '';
  };
  environment.etc."crowdsec/config.yaml".source =
    (pkgs.formats.yaml { }).generate "crowdsec.yaml"
      config.services.crowdsec.settings.general;
  # - the bouncer requires bouncer-register but isn't ordered after it
  systemd.services.crowdsec-firewall-bouncer.after = [ "crowdsec-firewall-bouncer-register.service" ];
  # Local parsers/scenarios change files under /etc but not the unit, so
  # crowdsec would keep running the old ones
  systemd.services.crowdsec.restartTriggers = [
    (builtins.toJSON config.services.crowdsec.localConfig)
  ];
  # update-hub reloads crowdsec as the unprivileged crowdsec user, which polkit
  # denies, and the unit has no ExecReload anyway; "+" restarts it as root
  # (still unfixed in unstable)
  systemd.services.crowdsec-update-hub.serviceConfig.ExecStartPost =
    lib.mkForce "+systemctl try-restart crowdsec.service";
  systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
    StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
    ReadWritePaths = [ "/var/lib/crowdsec" ];
  };

  # JSON access log for crowdsec, readable via the traefik group
  services.traefik.staticConfigOptions.accessLog = {
    filePath = traefikLog;
    format = "json";
    # Headers are dropped by default; the traefik parser wants User-Agent
    fields.headers.names.User-Agent = "keep";
  };
  systemd.services.traefik.serviceConfig = {
    LogsDirectory = "traefik";
    LogsDirectoryMode = "0750";
  };
  users.users.${config.services.crowdsec.user}.extraGroups = [ "traefik" ];

  services.logrotate.settings.traefik-access = {
    files = traefikLog;
    frequency = "daily";
    rotate = 7;
    copytruncate = true;
  };
}
