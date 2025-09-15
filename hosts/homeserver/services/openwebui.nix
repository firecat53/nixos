# Open-WebUI
{
  config,
  pkgs,
  ...
}:
{
  services.open-webui = {
    package = pkgs.unstable.open-webui;
    enable = true;
    port = 8083;
    # per https://github.com/NixOS/nixpkgs/pull/431395#issuecomment-3161532401
    # Fixes inability to setup initial user
    environment = {
      STATIC_DIR = "${config.services.open-webui.stateDir}/static";
      DATA_DIR = "${config.services.open-webui.stateDir}/data";
      HF_HOME = "${config.services.open-webui.stateDir}/hf_home";
      SENTENCE_TRANSFORMERS_HOME = "${config.services.open-webui.stateDir}/transformers_home";
    };
  };
  services.traefik.dynamicConfigOptions.http.routers.openwebui = {
    rule = "Host(`ai.lan.firecat53.net`)";
    service = "openwebui";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.openwebui = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:8083";
        }
      ];
    };
  };
}
