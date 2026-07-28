# Images for the wireguard pod, built with dockerTools
#
# `suffix` names the parallel test stack's images apart from production's, so
# each can be loaded and pruned without touching the other's tags. Temporary,
# along with qbittorrent-test.nix.
{
  pkgs,
  suffix ? "",
}:
{
  qbittorrent = import ./qbittorrent.nix { inherit pkgs suffix; };
  socks-proxy = import ./socks-proxy.nix { inherit pkgs suffix; };
  wireguard-client = import ./wireguard-client.nix { inherit pkgs suffix; };
}
