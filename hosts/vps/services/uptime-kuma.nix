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
  sops.secrets.airvpn-api-key = {};
  sops.secrets.kuma-monitor-id = {};
  environment.systemPackages = [
    (let
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        requests
      ]);
    in pkgs.writeScriptBin "check-airvpn-ip" ''
      #!${pythonEnv}/bin/python3
      import json
      import os
      import requests
      import sys
      import sqlite3
      from pathlib import Path

      KUMA_DB = "/var/lib/uptime-kuma/kuma.db"

      def get_sops_secret(key):
          with open(f"/run/secrets/{key}", "r") as f:
              return f.read().strip()

      def main():
          # Get secrets from sops-nix
          airvpn_api_key = get_sops_secret("airvpn-api-key")
          kuma_monitor_id = get_sops_secret("kuma-monitor-id")

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

          # Update the Uptime Kuma database
          if not Path(KUMA_DB).exists():
              print(f"Uptime Kuma database not found at {KUMA_DB}")
              sys.exit(1)

          try:
              conn = sqlite3.connect(KUMA_DB)
              cursor = conn.cursor()
              cursor.execute("UPDATE monitor SET hostname = ? WHERE id = ?", 
                           (server_ip, kuma_monitor_id))
              conn.commit()
              conn.close()
          except sqlite3.OperationalError as e:
              print(f"Database error: {str(e)}")
              sys.exit(1)
          finally:
              if conn:
                  conn.close()

          print(f"Successfully updated IP address to {server_ip}")

      if __name__ == "__main__":
          main()
    '')
  ];

  systemd.services.check-airvpn-ip = {
    description = "Check AirVPN IP and update Uptime Kuma";
    path = [
      (pkgs.python3.withPackages (ps: with ps; [ requests ]))
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
