# Podman monitoring and setup
{
  lib,
  pkgs,
  ...
}: let
  podman-py = p:
    [
      p.podman
    ];
in {
  environment.systemPackages = with pkgs; [
    (python311.withPackages podman-py // {meta.priority = 1;})
  ];

  virtualisation.podman = {
    enable = true;
    extraPackages = [pkgs.zfs];
  };

  virtualisation.containers.storage.settings = {
    storage = {
      driver = lib.mkDefault "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };
 
  environment.shellAliases = {
    pps = "podman ps --format 'table {{ .Names }}\t{{ .Status }}' --sort names";
    pclean = "podman ps -a | grep -v 'CONTAINER\|_config\|_data\|_run' | cut -c-12 | xargs podman rm 2>/dev/null";
    piclean = "podman images | grep '<none>' | grep -P '[1234567890abcdef]{12}' -o | xargs -L1 podman rmi 2>/dev/null";
  };
}
