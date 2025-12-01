{
  pkgs,
  ...
}:
{
  ## Enable OpenGL accelerated video playback
  ## https://wiki.nixos.org/wiki/Intel_Graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime # 13th gen and newer
      intel-media-driver
      vpl-gpu-rt # 11th gen and newer
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
