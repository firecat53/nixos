{
  ### Fail2ban
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    jails = {
      portscan = {
        settings = {
          enabled = true;
          filter = "portscan";
          backend = "systemd";
          maxretry = 5;
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
