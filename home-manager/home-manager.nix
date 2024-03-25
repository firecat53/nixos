{
  inputs,
  outputs,
  pkgs,
  ...
}:{
  # Home-manager configuration
  home-manager = {
    extraSpecialArgs = { 
      inherit inputs outputs pkgs ;
    };
  };
}
