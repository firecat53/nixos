{
  inputs,
  pkgs,
  ...
}:{
  home.packages = [
    inputs.cursor.packages.${pkgs.system}.default
  ];
}
