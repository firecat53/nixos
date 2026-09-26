{ pkgs, ... }:
let
  sshKeys = import ../../hosts/modules/common/ssh-keys.nix;
in
{
  # Trusted keys for verifying ssh-signed commits (git log --show-signature)
  programs.git = {
    enable = true;
    settings.gpg.ssh.allowedSignersFile = "${pkgs.writeText "allowed-signers" ''
      tech@firecat53.net ${sshKeys.devices.laptop}
      tech@firecat53.net ${sshKeys.devices.office}
      tech@firecat53.net ${sshKeys.signing}
    ''}";
  };
}
