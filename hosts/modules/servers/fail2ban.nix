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
    jails = {
      portscan = {
        settings = {
          enabled = true;
          filter = "portscan";
          backend = "systemd";
          maxretry = 20;
          findtime = 60;
          bantime = 3600;
          action = "iptables-allports[name=portscan, protocol=all]";
        };
      };
    };
  };
  environment.etc."fail2ban/filter.d/portscan.conf".text = ''
    [Definition]
    failregex = refused connection: .* SRC=<HOST>
  '';
}
