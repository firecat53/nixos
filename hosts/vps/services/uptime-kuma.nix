{
  pkgs,
  ...
}:
{
  # proxy-me.nix already resolves every registry `remote` .lan name to the
  # homeserver (networking.hosts merges across modules). Uptime-Kuma only
  # additionally monitors the Traefik dashboard, which is not proxied.
  networking.hosts.${(import ./registry.nix).hsIP} = [ "monitor.lan.firecat53.net" ];
  services.uptime-kuma = {
    enable = true;
  };
  # Public router is generated from registry.nix (local `up`, auth = true) by
  # proxy-me.nix, which wires the Authelia forward-auth + headers middlewares
  # and the two_factor access_control rule. Served at up.firecat53.me.
  #
  # With forward-auth guarding the public endpoint, Uptime Kuma's own login can
  # be disabled in its settings. The check-airvpn-ip script below tolerates
  # either state (it connects over localhost:3001, bypassing Traefik/Authelia).

  # Add script to check AirVPN exit IP and update Uptime Kuma
  # *NOTE* This may break with Uptime Kuma 2.x. API has not been updated in 2 years
  sops.secrets.airvpn-api-key = { };
  sops.secrets.kuma-monitor-id = { };
  sops.secrets.kuma-username = { };
  sops.secrets.kuma-password = { };

  environment.systemPackages = [
    (
      let
        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            requests
            uptime-kuma-api
          ]
        );
      in
      pkgs.writeScriptBin "check-airvpn-ip" ''
        #!${pythonEnv}/bin/python3
        import json
        import os
        import sys
        import time
        import requests
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

            # Update Uptime Kuma monitor. Connect directly to the local
            # instance (avoids the public TLS/Traefik round trip) and retry a
            # few times since the socket.io login can intermittently time out.
            attempts = 5
            for attempt in range(1, attempts + 1):
                api = None
                try:
                    api = UptimeKumaApi("http://localhost:3001", timeout=30)
                    # Authelia forward-auth (Traefik) now guards the public
                    # endpoint, so Uptime Kuma's own auth may be disabled. When
                    # it is, login() is rejected by the server -- treat that as
                    # non-fatal and proceed. A genuine (transient) login failure
                    # while auth is still enabled surfaces below as an
                    # edit_monitor error and is retried by the outer loop.
                    try:
                        api.login(kuma_username, kuma_password)
                    except Exception as login_err:
                        print(f"Skipping login (Uptime Kuma auth disabled?): {login_err}")
                    api.edit_monitor(id_=int(kuma_monitor_id), hostname=server_ip)
                    print(f"Successfully updated IP address to {server_ip}")
                    break
                except Exception as e:
                    print(f"Attempt {attempt}/{attempts} failed to update "
                          f"Uptime Kuma: {str(e)}")
                    if attempt == attempts:
                        sys.exit(1)
                    time.sleep(5)
                finally:
                    if api is not None:
                        try:
                            api.disconnect()
                        except Exception:
                            pass

        if __name__ == "__main__":
            main()
      ''
    )
  ];

  systemd.services.check-airvpn-ip = {
    description = "Check AirVPN IP and update Uptime Kuma";
    path = [
      (pkgs.python3.withPackages (
        ps: with ps; [
          requests
          uptime-kuma-api
        ]
      ))
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
