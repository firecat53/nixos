# PLACEHOLDER - exists only so .#minimal evaluates from a clean checkout.
# Overwrite it in place during a stage-1 install, before nixos-install:
#
#   nixos-generate-config --show-hardware-config --root /mnt \
#     > hosts/installer/minimal/hardware-configuration.nix
#
# Add --no-filesystems if disko is providing them.
{
}
