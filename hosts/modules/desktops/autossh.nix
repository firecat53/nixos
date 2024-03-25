{
  config,
  ...
}:{
  services.autossh.sessions = [
    {
      name = "wg";
      monitoringPort = 0;
      user = "firecat53";
      extraArguments = "-N -o ControlMaster=no wg";
    }
  ];
  systemd.services.autossh-wg.serviceConfig = {
    Environment = [
      "AUTOSSH_GATETIME=0"
      "SSH_AUTH_SOCK=/run/user/${toString config.users.users.firecat53.uid}/gnupg/S.gpg-agent.ssh"
    ];
  };
}
