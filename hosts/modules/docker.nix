# Docker
{
  pkgs,
  ...
}:{
  virtualisation.docker = {
    enable = true;
  };
  environment.systemPackages = [ pkgs.docker-compose ];
  users.users.firecat53.extraGroups = [ "docker" ];
}
