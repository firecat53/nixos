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

  # SSH identity for fetching the private `my-secrets` flake input (flake.nix). 
  # The host key doubles as the deploy key: it is already the sops age
  # identity, so anyone holding it can decrypt this host's secrets anyway and
  # read access to the encrypted repo grants nothing extra.  Authorize by adding
  # the host's public key (in ssh-keys.nix `hostKeys`) as a *read-only*
  # deploy key on the forgejo nixos-secrets repo — one per host, so a host can
  # be revoked on its own.
  programs.ssh.extraConfig = ''
    Host forgejo
      HostName git.firecat53.me
      Port 2222
      User forgejo
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
      PreferredAuthentications publickey
  '';

  networking.firewall.allowedTCPPorts = [ 22 ];
}
