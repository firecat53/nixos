{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.fastmail-imap = { };

  accounts.email = {
    # Maildir is synced from homeserver (where mbsync runs) by syncthing
    maildirBasePath = "mail";
    accounts."firecat53.net" = {
      primary = true;
      address = "scott@firecat53.net";
      realName = "Scott Hansen";
      flavor = "fastmail.com";
      passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.fastmail-imap.path}";
      aliases = [
        "tech@firecat53.net"
        "shopping@firecat53.net"
        "bills@firecat53.net"
        "health@firecat53.net"
      ];
      gpg = {
        key = "2BD1E9815C541EA2";
        signByDefault = true;
      };
    };
  };
}
