# Sonarr
{
  # Sonarr broken in 24.11 due to delayed sonarr update to .NET 8
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-wrapped-6.0.36"
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];

  services.sonarr = {
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/sonarr";
  };
  services.traefik.dynamicConfigOptions.http.routers.sonarr = {
    rule = "Host(`sonarr.lan.firecat53.net`)";
    service = "sonarr";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.sonarr = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8989";
        }
      ];
    };
  };
}
