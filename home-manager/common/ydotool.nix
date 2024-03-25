{
  pkgs,
  ...
}:{
  # Note: /dev/uinput needs 'user' group access. Add this to udev rules (or
  # system Nix config):
  #  services.udev.extraRules = ''
  #    KERNEL=="uinput", GROUP="users", MODE="0660",  OPTIONS+="static_node=uinput"
  #  '';
  systemd.user.services = {
    ydotool = {
      Unit = {
        Description = "Start ydotoold";
      };
      Service = {
        ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      };
    };
  };
}
