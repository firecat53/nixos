# ACLs and permissions for media and home folders
# - Ensure services running with `nextcloud` or `users` group can create/delete files
# - Ensure `users` group is set for newly created files/directories
#
# One-time setting `setgid` after adding this config (run as root):
#   fd -t d . /mnt/downloads /mnt/media /home/chryspie /home/firecat53/docs /home/firecat53/shared /home/morgan /home/nora /home/peggy /home/sydney -x chmod g+s {}
#
# The `a` (lowercase) ACL rule below is non-recursive: it sets the *default* ACL on
# each top dir only, which new files/dirs inherit automatically at creation time
# When adding a NEW dir here that already has pre-existing contents, apply the
# ACLs to them once, e.g.:
#   setfacl -R -m default:group:users:rwx <dir>   # (mirror the full acl set below)
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
    (map (dir: "d ${dir} 2775 firecat53 users - -") dirs)
    ++ (map (dir: "a ${dir} - - - - ${acls}") dirs);
}
