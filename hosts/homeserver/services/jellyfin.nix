# Jellyfin
{
  pkgs,
  ...
}:
{
  services.jellyfin = {
    enable = true;
    user = "firecat53";
    group = "users";
  };

  users.users.firecat53.extraGroups = [ "render" ];
  networking.firewall.allowedUDPPorts = [
    1900
    7359
  ];

  ## Enable OpenGL hardware transcoding for Jellyfin
  #nixpkgs.config.packageOverrides = pkgs: {
  #  intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  #};
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-ocl
      intel-media-driver
      #intel-vaapi-driver
      libva-vdpau-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  # Traefik routers/service generated from the registry (jellyfin entry) by lan-proxy.nix.
}
