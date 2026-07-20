### Stirling-PDF https://github.com/Stirling-Tools/Stirling-PDF
{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 8880;
    };
  };
  # Traefik routers/service generated from the registry (pdf entry) by lan-proxy.nix.
}
