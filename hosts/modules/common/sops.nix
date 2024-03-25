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
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    defaultSopsFile = "${secretspath}/${config.networking.hostName}/secrets.yaml";
  };
}
