{
  pkgs,
  ...
}:
{
  programs.uv = {
    enable = true;
  };
  # Allow building C extensions
  home.packages = [ pkgs.gcc ];
  home.sessionVariables = {
    C_INCLUDE_PATH = "${pkgs.linuxHeaders}/include";
  };
}
