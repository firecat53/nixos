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

  # For flake-lock-update. Deploy key: write on nixos, read on nixos-secrets.
  sops.secrets.nixos-ssh = { };
  # Commit signing key for flake-lock-update and for wiki.nix
  sops.secrets.signing-key = { };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."forgejo" = {
      HostName = "git.firecat53.me";
      Port = 2222;
      User = "forgejo";
      IdentityFile = config.sops.secrets.nixos-ssh.path;
      IdentitiesOnly = "yes";
      PreferredAuthentications = "publickey";
    };
  };

  # Age key that decrypts the user-level secrets. Can't use host key for this as
  # it is root owned.
  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = "${secretspath}/homeserver/secrets.yaml";
  };

  home.stateVersion = "26.05";
}
