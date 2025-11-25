{
  config,
  inputs,
  ...
}:
let
  secretspath = builtins.toString inputs.my-secrets;
in
{
  # Sops-nix
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = "${secretspath}/${config.networking.hostName}/secrets.yaml";
  };
  # Set github access token for nixpkgs
  sops.secrets.nix_access_token = {
    sopsFile = "${secretspath}/common/secrets.yaml";
    owner = "firecat53";
  };
  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_access_token.path}
  '';
}
