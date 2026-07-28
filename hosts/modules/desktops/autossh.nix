{
  config,
  ...
}:
{
  sops.secrets.autossh-key = {
    owner = "firecat53";
    mode = "0400";
  };

  services.autossh.sessions = [
    {
      name = "wg";
      monitoringPort = 0;
      user = "firecat53";
      extraArguments = "-N -o ControlMaster=no wg";
    }
    # Parallel test pod, SOCKS on 5002. Temporary, along with qbittorrent-test.nix.
    {
      name = "wg-test";
      monitoringPort = 0;
      user = "firecat53";
      extraArguments = "-N -o ControlMaster=no wg-test";
    }
  ];
  systemd.services.autossh-wg.serviceConfig = {
    Environment = [
      "AUTOSSH_GATETIME=0"
      "SSH_AUTH_SOCK=/run/user/${toString config.users.users.firecat53.uid}/gnupg/S.gpg-agent.ssh"
    ];
  };
  systemd.services.autossh-wg-test.serviceConfig = {
    Environment = [
      "AUTOSSH_GATETIME=0"
      "SSH_AUTH_SOCK=/run/user/${toString config.users.users.firecat53.uid}/gnupg/S.gpg-agent.ssh"
    ];
  };
}
