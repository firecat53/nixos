{
  pkgs,
  ...
}: let
  my-python-packages = ps:
    with ps; [
      ipython
      ipdb
      pip
      python-lsp-ruff
    ];
in {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (ps: with ps; [
      clang
      gnumake
      openssl.dev
      pkg-config
      (python312.withPackages my-python-packages)
      zlib
    ]);
  };
}
