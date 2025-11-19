# ACLs and permissions for home folders
# - Ensure services running with `nextcloud` or `users` group (on the server)
#   can create/delete files
# - Ensure `users` group is set for newly created files/directories
#
# One-time setting `setgid` after adding this config (run as root):
#   fd -t d . /home/firecat53/shared -x chmod g+sw {}
let
  dirs = [
    "/home/firecat53/shared"
  ];
  acls = "default:user::rwx,default:user:firecat53:rwx,default:group::rwx,default:group:users:rwx,default:mask::rwx,default:other::r-x";
in
{
  systemd.tmpfiles.rules =
    (map (dir: "d ${dir} 2775 firecat53 users - -") dirs)
    ++ (map (dir: "A ${dir} - - - - ${acls}") dirs);
}
