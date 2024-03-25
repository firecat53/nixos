{
  programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPath = "~/.ssh/socket-%r@%h:%p";
    controlPersist = "10m";
    matchBlocks = {
      "*" = {
        host = "*";
        serverAliveInterval = 30;
      };
      "home*" = {
        host = "home*";
        port = 22;
        user = "firecat53";
        identityFile = "~/.ssh/id_ed25519";
      };
      "homeserver*" = {
        host = "homeserver*";
        hostname = "lan.firecat53.net";
      };
      "homeserver_wg" = {
        localForwards = [
          {
            bind.address = "localhost";
            bind.port = 5001;
            host.address = "localhost";
            host.port = 5001;
          }
        ];
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
          ExitOnForwardFailure = "yes";
        };
      };
      "home" = {
        hostname = "192.168.200.101";
      };
      "backup" = {
        hostname = "backup";
        user = "firecat53";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };
      "vps" = {
        hostname = "firecat53.com";
        user = "firecat53";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };
      "github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github_ed25519";
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };
      "gist" = {
        hostname = "gist.github.com";
        user = "git";
        identityFile = "~/.ssh/github_ed25519";
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };
      "aur" = {
        hostname = "aur.archlinux.org";
        user = "aur";
        identityFile = "~/.ssh/aur";
      };
      "pfsense" = {
        hostname = "192.168.200.1";
        user = "admin";
        port = 3001;
        identityFile = "~/.ssh/id_ed25519";
      };
      "wg" = {
        hostname = "127.0.0.1";
        user = "firecat53";
        port = 2222;
        identityFile = "~/.ssh/deluge_ed25519";
        dynamicForwards = [
          {
            port = 5001;
          }
        ];
        proxyJump = "homeserver_wg";
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
          ExitOnForwardFailure = "yes";
        };
      };
    };
  };
}
