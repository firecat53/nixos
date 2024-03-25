{
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 7d";
  };
}
