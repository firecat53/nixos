# AirVPN forwarded-port monitoring script.
# A 15-minute timer resolves the current exit IP from the AirVPN API,
# TCP-tests <exit-ip>:27430, and writes a node-exporter textfile metric
# (airvpn_forwarded_port_up). Prometheus scrapes the VPS node-exporter already,
# and the alert rules live in prometheus.nix -> existing Alertmanager email.
#
# If the API query fails (or the session isn't found) the script does NOT
# rewrite the metric file: a transient API blip then surfaces as staleness
# (node_textfile_mtime_seconds), not a false "port down".
{
  config,
  pkgs,
  ...
}:
let
  textfileDir = "/var/lib/prometheus-node-exporter-text";
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.requests ]);
  checkScript = pkgs.writeScriptBin "airvpn-port-check" ''
    #!${pythonEnv}/bin/python3
    import os
    import socket
    import sys
    import tempfile

    import requests

    PORT = 27430
    DEVICE = "Server(QBT)"
    TEXTFILE = "${textfileDir}/airvpn.prom"
    API_KEY_PATH = "${config.sops.secrets.airvpn-api-key.path}"


    def read_secret(path):
        with open(path) as f:
            return f.read().strip()


    def tcp_ok(ip, port, attempts=3):
        for attempt in range(1, attempts + 1):
            try:
                with socket.create_connection((ip, port), timeout=10):
                    return 1
            except OSError as e:
                print(f"TCP attempt {attempt}/{attempts} to {ip}:{port} "
                      f"failed: {e}", file=sys.stderr)
        return 0


    def write_metrics(port_up, exit_ip):
        lines = [
            "# HELP airvpn_forwarded_port_up Whether the AirVPN forwarded port "
            "is reachable via TCP (1) or not (0).",
            "# TYPE airvpn_forwarded_port_up gauge",
            f'airvpn_forwarded_port_up{{port="{PORT}"}} {port_up}',
            "# HELP airvpn_exit_ip_info Current AirVPN exit IP for the "
            "qBittorrent session.",
            "# TYPE airvpn_exit_ip_info gauge",
            f'airvpn_exit_ip_info{{ip="{exit_ip}"}} 1',
        ]
        data = "\n".join(lines) + "\n"
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(TEXTFILE), suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
                f.write(data)
            os.chmod(tmp, 0o644)
            os.replace(tmp, TEXTFILE)  # atomic: node-exporter never sees a partial file
        except Exception:
            if os.path.exists(tmp):
                os.unlink(tmp)
            raise


    def get_exit_ip(api_key):
        r = requests.get(
            "https://airvpn.org/api/userinfo/",
            headers={"API-KEY": api_key},
            timeout=20,
        )
        data = r.json()
        if r.status_code != 200 or data.get("result") != "ok":
            raise RuntimeError(f"AirVPN API returned {r.status_code} / "
                               f"{data.get('result')!r}")
        for session in data.get("sessions", []):
            if session.get("device_name") == DEVICE:
                return session.get("exit_ipv4")
        raise RuntimeError(f"no active AirVPN session named {DEVICE!r}")


    def main():
        api_key = read_secret(API_KEY_PATH)
        try:
            exit_ip = get_exit_ip(api_key)
        except (requests.RequestException, ValueError, RuntimeError) as e:
            # Leave the previous metric file in place; staleness alert covers
            # a sustained API/script outage.
            print(f"Could not determine AirVPN exit IP: {e}", file=sys.stderr)
            sys.exit(0)

        port_up = tcp_ok(exit_ip, PORT)
        write_metrics(port_up, exit_ip)
        print(f"exit_ip={exit_ip} port_{PORT}_up={port_up}")


    if __name__ == "__main__":
        main()
  '';
in
{
  sops.secrets.airvpn-api-key = { };

  # node-exporter (scraped on the VPS already) reads .prom files from this
  # directory and exposes their metrics. The collector flag is set in
  # modules/servers/prometheus-exporters.nix; just ensure the dir exists on the
  # VPS (homeserver creates it in misc.nix) so the script can write airvpn.prom.
  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 root root -"
  ];

  systemd.services.airvpn-port-check = {
    description = "Check AirVPN forwarded port (27430) and export a metric";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${checkScript}/bin/airvpn-port-check";
    };
  };

  systemd.timers.airvpn-port-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
      Unit = "airvpn-port-check.service";
    };
  };
}
