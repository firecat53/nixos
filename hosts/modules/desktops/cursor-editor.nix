{
  cursor,
  pkgs,
  ...
}:{
  environment.systemPackages = [
    cursor.packages.${pkgs.system}.default
  ];
}
