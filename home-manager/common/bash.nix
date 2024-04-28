{
  config,
  ...
}:{
  # ENV variables

  home.sessionPath = [
    "$HOME/.local/bin"
    "/var/lib/flatpak/exports/bin"
  ];

  # Bash config
  sops.secrets.hcloud-token = {};
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = ["ignoredups" "ignorespace"];
    profileExtra = ''
      systemctl --user import-environment DESKTOP_SESSION
      export XDG_DATA_DIRS=$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share
    '';
    shellAliases = {
      ".." = "cd ..";
      ave = "ansible-vault edit --vault-password-file=/home/firecat53/docs/family/scott/src/ansible/ansible_vault_password.py";
      avv = "ansible-vault view --vault-password-file=/home/firecat53/docs/family/scott/src/ansible/ansible_vault_password.py";
      bu = "et backup -c 'tmux new-session -A -s term'";
      buw = "et firecat53@10.200.200.4 -c 'tmux new-session -A -s term'";
      pclean = "podman ps -a | grep -v 'CONTAINER\|_config\|_data\|_run' | cut -c-12 | xargs podman rm 2>/dev/null";
      piclean = "podman images | grep '<none>' | grep -P '[1234567890abcdef]{12}' -o | xargs -L1 podman rmi 2>/dev/null";
      hmd = "nix store diff-closures $(home-manager generations | head -n2 | awk '{printf \"%s \", $NF}')";
      hmu = "nix flake update $HOME/nixos/nixos/home-manager/ && home-manager switch --flake /home/firecat53/nixos/nixos/home-manager";
      hs = "et homeserver -c 'tmux new-session -A -s term'";
      la = "ls -a --color=auto";
      ll = "ls -l --color=auto";
      lla = "ls -la --color=auto";
      lr = "ls -lR";
      ls = "ls --color=auto";
      lsa = "grep alias ~/.bashrc";
      lsd = "ls -dl */";
      ni = "nix-store --query --requisites ~/.nix-profile | cut -d\- -f2- | sort | bat";
      pas = "pbincli send";
      sd = "sudo systemctl poweroff";
      sdr = "sudo systemctl reboot";
      t = "tmux new-session -A -s term";
      ua = "udiskie-umount -a";
      um = "udiskie-mount";
      uu = "udiskie-umount";
      vps = "et vps -c 'tmux new-session -A -s term'";
      wanip = "curl ipinfo.io/ip";
    };
    initExtra = ''
      export HCLOUD_TOKEN=$(cat "$HOME/.config/sops-nix/secrets/hcloud-token")
    '';
  };

  ## Bat
  programs.bat = {
    enable = true;
    config = {
      theme = "Monokai Extended";
    };
  };

  ## Fzf
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type d --hidden --follow --exclude .git -E .vim -E .cache -E .nvm -E .cargo -E .local/src -E .local/srv/git -E .vscode-oss -E .local/lib -E .vagrant.d -E .local/share/containers -E .nix-defexpr -E .nix-profile -E .local/state";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git -E .vim -E .cache -E .nvm -E .cargo -E .local/src -E .local/srv/git -E .vscode-oss -E .local/lib -E .vagrant.d -E .local/share/containers -E .nix-defexpr -E .nix-profile -E .local/state";
    fileWidgetCommand = "fd --type d --hidden --follow --exclude .git -E .vim -E .cache -E .nvm -E .cargo -E .local/src -E .local/srv/git -E .vscode-oss -E .local/lib -E .vagrant.d -E .local/share/containers -E .nix-defexpr -E .nix-profile -E .local/state";
    tmux.enableShellIntegration = true;
    tmux.shellIntegrationOptions = ["-d 40%"];
  };

  ## Starship
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };


}
