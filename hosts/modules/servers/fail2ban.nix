{
  ### Fail2ban
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
  };
}
