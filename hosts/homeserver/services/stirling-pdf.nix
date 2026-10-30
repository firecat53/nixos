### Stirling-PDF https://github.com/Stirling-Tools/Stirling-PDF
{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 8880;
    };
  };
  # Disable test failing with Pillow 13 (2026-10-30). Remove once nixpkgs#580486
  # reaches the nixos-26.05 channel.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          fpdf2 = pyprev.fpdf2.overridePythonAttrs (old: {
            disabledTests = old.disabledTests ++ [ "test_image_with_explicit_dimensions" ];
          });
        })
      ];
    })
  ];
  # Traefik routers/service generated from the registry (pdf entry) by lan-proxy.nix.
}
