{
  config,
  ...
}:
{
  ### Msmtp
  #### Note: see vps/prometheus.nix for how to use systemd load credentials
  #### for services with DynamicUser=true so that the credential permissions can
  #### be kept at 0400
  #### Otherwise, add any service that needs access to the 'msmtp' group

  users.groups.msmtp = { };

  sops.secrets.email-password = {
    mode = "0440";
    group = "msmtp";
  };

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = true;
      auth = true;
      tls_starttls = false;
    };
    accounts = {
      default = {
        host = "smtp.fastmail.com";
        passwordeval = "cat ${config.sops.secrets.email-password.path}";
        user = "scott@firecat53.net";
        from = "noreply@firecat53.net";
      };
    };
  };
}
