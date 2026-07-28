{
  inputs,
  ...
}:
{
  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}
