{
  # Backup user for pull backups from backup server
  users.users.backup = {
    isNormalUser = true;
    uid = 20001;
    group = "root";
    home = "/var/lib/backup";
    createHome = true;
    openssh.authorizedKeys.keys = [
      (import ../common/ssh-keys.nix).backupPull
    ];
  };
}
