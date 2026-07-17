{
  ### SSH
  # Verified host keys
  programs.ssh.knownHosts = (import ./ssh-keys.nix).hostKeys;

  services.openssh.enable = true;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.X11Forwarding = false;
  services.openssh.extraConfig = ''
    UsePAM yes
    PrintMotd no
    TCPKeepAlive yes
    ClientAliveInterval 30
  '';

  networking.firewall.allowedTCPPorts = [ 22 ];
}
