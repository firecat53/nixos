{
  pkgs,
  ...
}:
{
  # The account itself is shared with the desktops
  imports = [ ../common/mail.nix ];

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
  accounts.email.accounts."firecat53.net".mbsync = {
    enable = true;
    create = "both";
    expunge = "both";
    flatten = ".";
    patterns = [ "*" ];
  };
}
