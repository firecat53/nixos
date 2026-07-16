{
  config,
  lib,
  ...
}:
{
  ### Eternal Terminal
  services.eternal-terminal.enable = true;

  # Only open 2022 on LAN hosts (behind NAT, so LAN/wireguard exposure only).
  # Remote hosts keep the port closed publicly; ET remains reachable over
  # wg0, which is a trusted interface.
  networking.firewall.allowedTCPPorts = lib.mkIf (!config.isRemote) [ 2022 ];
}
