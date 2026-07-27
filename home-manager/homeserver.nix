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

  # forgejo alias for flake-lock-update. Overrides the system-wide alias, whose
  # host-key identity can't push. Deploy key: write on nixos, read on
  # nixos-secrets (needed by `nix flake update`).
  sops.secrets.nixos-ssh = { };
  # Commit signing key for flake-lock-update. Also declared by wiki.nix
  # (identical declarations merge); declared here so lock-bump signing
  # doesn't silently depend on wiki.nix staying imported.
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

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = "${secretspath}/homeserver/secrets.yaml";
  };

  home.stateVersion = "26.05";
}
