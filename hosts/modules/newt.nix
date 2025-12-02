# Add the Newt wireguard tunnel utility for Pangolin
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.newt-env = { };

  services.newt = {
    enable = true;
    package = pkgs.fosrl-newt;
    environmentFile = "${config.sops.secrets.newt-env.path}";
  };
}
