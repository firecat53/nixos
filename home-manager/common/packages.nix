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
    bitwarden-cli
    exiftool
    gomuks
    hcloud
    home-manager
    mediainfo
    ncspot
    pianobar
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
    inputs.bwm.packages.${pkgs.system}.default
    dmenu
    electrum
    firefox
    hunspell
    hunspellDicts.en-us-large
    imv
    keepassxc
    inputs.keepmenu.packages.${pkgs.system}.default
    libreoffice
    mpv
    pinentry-qt
    resources
    ripdrag
    simple-scan
    spotify
    inputs.todocalmenu.packages.${pkgs.system}.default
    ungoogled-chromium
    inputs.urlscan.packages.${pkgs.system}.default
    ventoy
    wl-clipboard
    zathura
    zoom-us
  ];
}
