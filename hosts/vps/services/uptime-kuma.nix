{
  pkgs,
  ...
}:{
  # Services on homeserver that need monitoring
  networking.extraHosts = ''
    10.200.200.6 bw.lan.firecat53.net
    10.200.200.6 cars.lan.firecat53.net
    10.200.200.6 gollum.lan.firecat53.net
    10.200.200.6 hass.lan.firecat53.net
    10.200.200.6 jellyfin.lan.firecat53.net
    10.200.200.6 monitor.lan.firecat53.net
    10.200.200.6 nc.firecat53.net
    10.200.200.6 pdf.lan.firecat53.net
    10.200.200.6 qbt.lan.firecat53.net
    10.200.200.6 radarr.lan.firecat53.net
    10.200.200.6 rss.lan.firecat53.net
    10.200.200.6 sabnzbd.lan.firecat53.net
    10.200.200.6 sonarr.lan.firecat53.net
    10.200.200.6 syncthing.lan.firecat53.net
    10.200.200.6 transmission.lan.firecat53.net
  '';
  services.uptime-kuma = {
    enable = true;
  };
  services.traefik.dynamicConfigOptions.http.routers.up = {
    rule = "Host(`up.firecat53.com`)";
    service = "up";
    middlewares = ["headers"];
    entrypoints = ["websecure"];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.up = {
    loadBalancer = {
      servers = [
        {
          url = "http://localhost:3001";
        }
      ];
    };
  };

  # Add script to check AirVPN exit IP and update Uptime Kuma
  # *NOTE* This may break with Uptime Kuma 2.x. API has not been updated in 2 years
  sops.secrets.airvpn-api-key = {};
  sops.secrets.kuma-monitor-id = {};
  sops.secrets.kuma-username = {};
  sops.secrets.kuma-password = {};

  environment.systemPackages = [
    (let
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        requests
        uptime-kuma-api
      ]);
    in pkgs.writeScriptBin "check-airvpn-ip" ''
      #!${pythonEnv}/bin/python3
      import json
      import os
      import requests
      import sys
      from uptime_kuma_api import UptimeKumaApi
      from uptime_kuma_api.exceptions import UptimeKumaException

      def get_sops_secret(key):
          with open(f"/run/secrets/{key}", "r") as f:
              return f.read().strip()

      def main():
          # Get secrets from sops-nix
          airvpn_api_key = get_sops_secret("airvpn-api-key")
          kuma_monitor_id = get_sops_secret("kuma-monitor-id")
          kuma_username = get_sops_secret("kuma-username")
          kuma_password = get_sops_secret("kuma-password")

          # Get AirVPN status
          try:
              headers = {"API-KEY": airvpn_api_key}
              r = requests.get("https://airvpn.org/api/userinfo/", headers=headers)
              data = r.json()

              if r.status_code != 200 or data.get("result") != "ok":
                  print("Failed to get AirVPN status")
                  sys.exit(1)
          except requests.exceptions.RequestException as e:
              print(f"Failed to connect to AirVPN API: {str(e)}")
              sys.exit(1)
          except json.JSONDecodeError as e:
              print(f"Failed to parse AirVPN API response: {str(e)}")
              sys.exit(1)

          # Find the Server(QBT) connection
          server_ip = None
          for session in data.get("sessions", []):
              if session.get("device_name") == "Server(QBT)":
                  server_ip = session.get("exit_ipv4")
                  break

          if not server_ip:
              print("Could not find Server(QBT) connection")
              sys.exit(1)

          # Update Uptime Kuma monitor
          try:
              api = UptimeKumaApi("https://up.firecat53.com")
              api.login(kuma_username, kuma_password)
              api.edit_monitor(id_=int(kuma_monitor_id), hostname=server_ip)
          except UptimeKumaException as e:
              print(f"Failed to update Uptime Kuma: {str(e)}")
              sys.exit(1)
          finally:
              api.disconnect()

          print(f"Successfully updated IP address to {server_ip}")

      if __name__ == "__main__":
          main()
    '')
  ];

  systemd.services.check-airvpn-ip = {
    description = "Check AirVPN IP and update Uptime Kuma";
    path = [
      (pkgs.python3.withPackages (ps: with ps; [ requests uptime-kuma-api ]))
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/check-airvpn-ip";
    };
  };

  systemd.timers.check-airvpn-ip = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "15m";
      Unit = "check-airvpn-ip.service";
    };
  };
}
