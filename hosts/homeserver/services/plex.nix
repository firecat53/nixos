# Plex
{
  services.plex = {
    enable = true;
    user = "firecat53";
    group = "users";
    openFirewall = true;
  };
}
