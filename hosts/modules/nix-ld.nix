{
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = true;
    # put whatever libraries you think you might need
    # nix-ld includes a strong sane-default as well
    # in addition to these
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];
  };
}
