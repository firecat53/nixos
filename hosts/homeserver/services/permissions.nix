# ACLs and permissions for media and home folders
# - Ensure services running with `nextcloud` or `users` group can create/delete files
# - Ensure `users` group is set for newly created files/directories
#
# One-time setting `setgid` after adding this config (run as root):
#   fd -t d . /mnt/downloads /mnt/media /home/chryspie /home/firecat53/docs /home/firecat53/shared /home/morgan /home/nora /home/peggy /home/sydney -x chmod g+s {}
let
  dirs = [
    "/home/chryspie"
    "/home/firecat53/docs"
    "/home/firecat53/shared"
    "/home/morgan"
    "/home/nora"
    "/home/peggy"
    "/home/sydney"
    "/mnt/downloads"
    "/mnt/media"
  ];
  acls = "default:user::rwx,default:user:firecat53:rwx,default:group::rwx,default:group:users:rwx,default:mask::rwx,default:other::r-x";
in
{
  systemd.tmpfiles.rules =
    (map (dir: "d ${dir} 2775 firecat53 users - -") dirs) ++
    (map (dir: "A ${dir} - - - - ${acls}") dirs);
}
