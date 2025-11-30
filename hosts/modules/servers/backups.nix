{
  # Backup user for pull backups from backup server
  users.users.backup = {
    isNormalUser = true;
    uid = 20001;
    group = "root";
    home = "/var/lib/backup";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+gF2w6+0Rj9XFl9e8NcWRux5dKsyAMcgoM6KDH11E backup@backup"
    ];
  };
}
