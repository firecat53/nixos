{
  config,
  pkgs,
  ...
}:
let
  eventCommand = pkgs.writeShellScript "pianobar-event-command" ''
    if [ "$1" = "songstart" ]; then
      mkdir -p ~/.config/pianobar
      cat > ~/.config/pianobar/nowplaying
    fi
  '';
in
{
  sops.secrets.pianobar-password = { };

  programs.pianobar = {
    enable = true;
    package = pkgs.pianobar;
    settings = {
      event_command = "${eventCommand}";
      password_command = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.pianobar-password.path}";
      user = "fun@firecat53.net";
    };
  };
}
