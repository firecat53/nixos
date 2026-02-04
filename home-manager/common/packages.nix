{
  inputs,
  pkgs,
  ...
}:
let
  my-python-packages =
    ps: with ps; [
      ansible
      ansible-core
      grip
      ipython
      ipdb
      pip
      podman
      python-lsp-ruff
    ];
in
{
  home.packages = with pkgs; [
    # Terminal tools
    age
    atool
    autossh
    bottom
    distrobox
    dua
    eternal-terminal
    fd
    file
    mosh
    p7zip
    ripgrep
    sops
    stow
    udiskie
    unzip
    # Terminal applications
    andcli
    bitwarden-cli
    exiftool
    gomuks
    hcloud
    home-manager
    jellyfin-tui
    mediainfo
    rendercv
    sshfs
    tabview
    todoman
    w3m
    # Development tools
    ctags
    highlight
    (python3.withPackages my-python-packages)
    ruff
    tig
    uv
    # Gui applications
    anydesk
    inputs.bwm.packages.${pkgs.stdenv.hostPlatform.system}.default
    dmenu
    electrum
    firefox
    hunspell
    hunspellDicts.en-us-large
    imv
    keepassxc
    inputs.keepmenu.packages.${pkgs.stdenv.hostPlatform.system}.default
    libreoffice
    pinentry-qt
    resources
    ripdrag
    simple-scan
    spotify
    inputs.todocalmenu.packages.${pkgs.stdenv.hostPlatform.system}.default
    ungoogled-chromium
    inputs.urlscan.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.watson-dmenu.packages.${pkgs.stdenv.hostPlatform.system}.default
    wl-clipboard
    zathura
    zoom-us
  ];
}
