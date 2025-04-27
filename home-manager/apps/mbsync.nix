{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.fastmail-imap = { };
  home.packages = [
    pkgs.isync
  ];

  programs.mbsync = {
    enable = true;
    extraConfig = ''
      CopyArrivalDate yes
    '';
  };
  services.mbsync = {
    enable = true;
    frequency = "*:0/2";
    verbose = false;
  };
  accounts.email = {
    maildirBasePath = "mail";
    accounts."firecat53.net" = {
      address = "scott@firecat53.net";
      primary = true;
      userName = "scott@firecat53.net";
      passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.fastmail-imap.path}";
      flavor = "fastmail.com";
      aliases = [
        "tech@firecat53.net"
        "shopping@firecat53.net"
        "bills@firecat53.net"
        "health@firecat53.net"
      ];
      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
        flatten = ".";
        patterns = [ "*" ];
      };
    };
  };
}
