# Images for the wireguard pod, built with dockerTools
{
  pkgs,
  uid,
  gid,
}:
{
  qbittorrent = import ./qbittorrent.nix { inherit pkgs uid gid; };
  socks-proxy = import ./socks-proxy.nix { inherit pkgs; };
  wireguard-client = import ./wireguard-client.nix { inherit pkgs; };
}
