### Stirling-PDF https://github.com/Stirling-Tools/Stirling-PDF
{
  virtualisation.oci-containers.containers.stirling-pdf = {
    image = "frooodle/s-pdf:latest";
    autoStart = true;
    environment = {
      DOCKER_ENABLE_SECURITY = "False";
    };
    extraOptions = [
      "--init=true"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.stirling-pdf.rule=Host(`pdf.lan.firecat53.net`)"
      "--label=traefik.http.routers.stirling-pdf.entrypoints=websecure"
      "--label=traefik.http.routers.stirling-pdf.tls.certResolver=le"
      "--label=traefik.http.routers.stirling-pdf.middlewares=headers@file"
      "--label=traefik.http.services.stirling-pdf.loadbalancer.server.port=8080"
    ];
    volumes = [
      "pdf_training_data:/usr/share/tesseract-ocr/5/tessdata"
      "pdf_configs:/configs"
      "pdf_logs:/logs"
    ];
  };
}
