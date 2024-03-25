{
  users.users.root = {
    ## hash: mkpasswd -m SHA-512 -s (initial password: rootpassword)
    initialHashedPassword = "$6$SJ9TnC7TNPD86lkT$mXAlVO2L6aIaA9mtrCQTWTKNyZbETKZ2XhHOoDPWMFGnZF3vdqIBtHmHVJICNTP/yCgj28OMAsAm8wC1JM1Ui/";
  };

  # Normal user
  users.users.firecat53 = {
    isNormalUser = true;
    group = "firecat53";
    extraGroups = ["wheel" "networkmanager" "libvirtd"];
    uid = 1000;
    # initial password: firecat53
    initialHashedPassword = "$6$4uca2AGtTNxwo1bt$JJwaaNTqKF6ddXE9xLqWdmTZpElZZ5KNHEbj4jqAVY5QVknWKB4lCvzlMPZ0VLivh8FcmpGbkx5bVJhT1URpz0";
    # keys: id_ed25519.pub
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdMFWLeCpeDFMKJyLaTtLgmfJ6G8HxrBObvlaBE8eoH firecat53@scotty"
    ];
  };
  users.groups.firecat53 = {
    gid = 1000;
  };
}
