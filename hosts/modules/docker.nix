# Docker
{
  virtualisation.docker = {
    enable = true;
  };
  users.users.firecat53.extraGroups = [ "docker" ];
}
