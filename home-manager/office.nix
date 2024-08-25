{
  config,
  inputs,
  sops-nix,
  ...
}:
let
  secretspath = builtins.toString inputs.my-secrets;
in
  {
  imports = [
    ./common
    ./sway
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  home.username = "firecat53";
  home.homeDirectory = "/home/firecat53";
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = "${secretspath}/office/secrets.yaml";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}
