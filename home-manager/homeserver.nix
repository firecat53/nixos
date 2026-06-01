{
  config,
  inputs,
  ...
}:
let
  secretspath = builtins.toString inputs.my-secrets;
in
{
  imports = [
    ./apps/beets.nix
    ./apps/mbsync.nix
    ./apps/vdirsyncer.nix
    ./apps/wiki.nix
  ];

  home.username = "firecat53";
  home.homeDirectory = "/home/firecat53";

  programs.home-manager.enable = true;

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = "${secretspath}/homeserver/secrets.yaml";
  };

  home.stateVersion = "26.05";
}
