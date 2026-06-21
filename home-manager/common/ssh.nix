{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "Host *" = {
        ServerAliveInterval = 30;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/socket-%r@%h:%p";
        ControlPersist = "10m";
      };
      # NOTE: forwardAgent stays only on hosts where pam_rssh sudo auth is needed.
      ## Servers
      "Host home*" = {
        Port = 22;
        User = "firecat53";
        IdentityFile = "~/.ssh/id_ed25519";
        ForwardAgent = true;
      };
      "Host homeserver*" = {
        HostName = "lan.firecat53.net";
      };
      "Host homeserver_wg" = {
        LocalForward = [
          {
            bind.address = "localhost";
            bind.port = 5001;
            host.address = "localhost";
            host.port = 5001;
          }
        ];
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        ExitOnForwardFailure = "yes";
      };
      "Host home" = {
        HostName = "192.168.200.101";
      };
      "Host backup" = {
        HostName = "backup";
        User = "firecat53";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
        ForwardAgent = true;
      };
      # HASS: device key authorized as root (no sudo on hass, no agent forward).
      "Host hass" = {
        HostName = "192.168.200.102";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "Host router" = {
        HostName = "192.168.200.1";
        User = "firecat53";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "Host vps" = {
        HostName = "firecat53.com";
        User = "firecat53";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
        ForwardAgent = true;
      };
      ## Desktop/laptops
      "Host laptop" = {
        HostName = "laptop";
        User = "firecat53";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "Host office" = {
        HostName = "office";
        User = "firecat53";
        Port = 22;
        IdentityFile = "~/.ssh/id_ed25519";
      };
      ## ProxyJump to homeserver->socks-proxy
      "Host wg" = {
        HostName = "127.0.0.1";
        User = "firecat53";
        Port = 2222;
        IdentityFile = "/run/secrets/autossh-key";
        DynamicForward = "127.0.0.1:5001";
        ProxyJump = "homeserver_wg";
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        ExitOnForwardFailure = "yes";
      };
      # Git remotes use the device key directly — add this device's pubkey to
      # GitHub/forgejo accounts. No agent forwarding (no shell on these hosts).
      "Host forgejo" = {
        HostName = "git.firecat53.me";
        Port = 2222;
        User = "forgejo";
        IdentityFile = "~/.ssh/id_ed25519";
        PreferredAuthentications = "publickey";
      };
      "Host github" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        PreferredAuthentications = "publickey";
      };
      "Host gist" = {
        HostName = "gist.github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        PreferredAuthentications = "publickey";
      };
      ## AUR
      "aur" = {
        HostName = "aur.archlinux.org";
        User = "aur";
        IdentityFile = "~/.config/sops-nix/secrets/aur-key";
      };
    };
  };
  # Declare AUR SSH key
  sops.secrets.aur-key = { };
}
