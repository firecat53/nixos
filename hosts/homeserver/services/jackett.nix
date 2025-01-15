# Jackett
{
  pkgs,
  ...
}:{
  services.jackett = {
    package = pkgs.jackett;
    enable = true;
    user = "firecat53";
    group = "users";
    dataDir = "/var/lib/jackett";
  };
  # Disable failing tests (2025-01-15)
  nixpkgs.overlays = [ 
    (final: prev: { 
      jackett = prev.jackett.overrideAttrs { doCheck = false; }; 
    })
  ];
  services.traefik.dynamicConfigOptions.http.routers.jackett = {
    rule = "Host(`jackett.lan.firecat53.net`)";
    service = "jackett";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.jackett = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:9117";
        }
      ];
    };
  };
}
