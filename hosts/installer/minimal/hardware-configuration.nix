# PLACEHOLDER - exists only so .#minimal evaluates from a clean checkout.
# Overwrite it in place during a stage-1 install, before nixos-install:
#
#   nixos-generate-config --show-hardware-config --root /mnt \
#     > hosts/installer/minimal/hardware-configuration.nix
#
# Never add --no-filesystems: #minimal doesn't import disko, so this is its
# only fileSystems source.
{
}
