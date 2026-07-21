{ ... }:
{
  # Enable building aarch64-linux (e.g. Rasp Pi)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
