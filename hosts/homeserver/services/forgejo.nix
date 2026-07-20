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
        START_SSH_SERVER = true;
        SSH_LISTEN_PORT = 3022; # fix conflict with QBT
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
  };

  # Traefik routers/service generated from the registry (git entry) by lan-proxy.nix.
}
