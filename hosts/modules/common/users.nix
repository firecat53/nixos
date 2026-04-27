{ ... }:
let
  sshKeys = import ./ssh-keys.nix;
in
{
  users.users.root = {
    ## hash: mkpasswd -m SHA-512 -s (initial password: rootpassword)
    initialHashedPassword = "$6$SJ9TnC7TNPD86lkT$mXAlVO2L6aIaA9mtrCQTWTKNyZbETKZ2XhHOoDPWMFGnZF3vdqIBtHmHVJICNTP/yCgj28OMAsAm8wC1JM1Ui/";
  };

  # Normal user
  users.users.firecat53 = {
    isNormalUser = true;
    group = "firecat53";
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "users"
      "wheel"
    ];
    uid = 1000;
    # initial password: firecat53
    initialHashedPassword = "$6$4uca2AGtTNxwo1bt$JJwaaNTqKF6ddXE9xLqWdmTZpElZZ5KNHEbj4jqAVY5QVknWKB4lCvzlMPZ0VLivh8FcmpGbkx5bVJhT1URpz0";
    # One pubkey per device; private halves never leave the host they were generated on.
    openssh.authorizedKeys.keys = builtins.attrValues sshKeys.devices;
  };
  users.groups.firecat53 = {
    gid = 1000;
  };

  # Setup PAM to use SSH key as sudo auth if available.
  security = {
    sudo.execWheelOnly = true;

    pam = {
      rssh = {
        enable = true;
        settings.auth_key_file = "/etc/ssh/authorized_keys.d/firecat53";
      };
      services.sudo.rssh = true;
    };
  };
}
