# Forgejo
{
  pkgs,
  ...
}:
{
  users.users.forgejo.extraGroups = [ "msmtp" ];

  services.forgejo = {
    database.type = "postgres";
    enable = true;
    # Disable tests due to TestBleveDeleteIssue failure in 14.0.4 TODO
    package = pkgs.forgejo.overrideAttrs { doCheck = false; };
    settings = {
      cache = {
        ADAPTER = "twoqueue";
        HOST = ''{"size":50000,"recent_ratio":0.25,"ghost_ratio":0.5}'';
      };
      cron = {
        ENABLED = true;
      };
      log.LEVEL = "Warn";
      mailer = {
        ENABLED = true;
        ENABLE_NOTIFY_MAIL = true;
        FROM = "noreply@firecat53.net";
        PROTOCOL = "sendmail";
        SENDMAIL_ARGS = " --";
        SENDMAIL_PATH = "${pkgs.msmtp}/bin/sendmail";
      };
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };
      picture.DISABLE_GRAVATAR = true;
      repository = {
        ENABLE_PUSH_CREATE_USER = true;
        ENABLE_PUSH_CREATE_ORG = true;
      };
      "repository.signing".DEFAULT_TRUST_MODEL = "collaborator";
      security.LOGIN_REMEMBER_DAYS = 365;
      server = {
        DOMAIN = "git.firecat53.me";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3100;
        ROOT_URL = "https://git.firecat53.me/";
        SSH_DOMAIN = "git.firecat53.me";
        SSH_PORT = 2222;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
  };

  services.openssh.extraConfig = ''
    AcceptEnv GIT_PROTOCOL
  '';

  services.traefik.dynamicConfigOptions.http.routers.forgejo = {
    rule = "Host(`git.lan.firecat53.net`)";
    service = "forgejo";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls.certResolver = "le";
  };
  services.traefik.dynamicConfigOptions.http.services.forgejo = {
    loadBalancer.servers = [
      {
        url = "http://localhost:3100";
      }
    ];
  };
}
