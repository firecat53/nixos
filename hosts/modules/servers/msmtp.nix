{
  config,
  ...
}:{
  ### Msmtp
  sops.secrets.email-password = {
    # This has to be world readable because I can't set ACLs with sops-nix for the 
    #   systemd dynamic users. TODO
    mode = "0444";
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
