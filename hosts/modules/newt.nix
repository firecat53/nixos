# Add the Newt wireguard tunnel utility for Pangolin
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    inputs.newt.packages.${pkgs.system}.default
  ];

  sops.secrets.newt-env = { };

  systemd.services.newt-vpn = {
    description = "Newt VPN Client";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ inputs.newt.packages.${pkgs.system}.default ];
    serviceConfig = {
      ExecStart = "${inputs.newt.packages.${pkgs.system}.default}/bin/newt";
      EnvironmentFile = "${config.sops.secrets.newt-env.path}";
      Restart = "always";
      DynamicUser = true;
      Environment = "HOME=%t/newt-vpn";
      RuntimeDirectory = "newt-vpn";
      RuntimeDirectoryMode = "0700";
    };
  };
}
