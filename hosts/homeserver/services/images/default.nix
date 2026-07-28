# Images for the wireguard pod, built with dockerTools
{ pkgs }:
{
  qbittorrent = import ./qbittorrent.nix { inherit pkgs; };
  socks-proxy = import ./socks-proxy.nix { inherit pkgs; };
  wireguard-client = import ./wireguard-client.nix { inherit pkgs; };
}
