{
  pkgs,
  ...
}:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb_114;
  };

  # Mysql/maridb backup
  services.mysqlBackup = {
    enable = true;
    location = "/var/lib/backups/mysql";
    databases = [ "nextcloud" ];
    singleTransaction = true;
    user = "mysql";
  };
}
