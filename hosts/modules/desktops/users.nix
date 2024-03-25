{
  ### Make firecat53 admin user on desktops
  users.users.firecat53 = {
    extraGroups = [
      "libvirtd"
      "networkmanager"
      "users"
      "wheel"
    ];
  };
} 
