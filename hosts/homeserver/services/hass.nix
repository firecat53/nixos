# Home Assistant - VM behind Traefik
{
  pkgs,
  ...
}:
{
  services.traefik.dynamicConfigOptions.http.routers.hass = {
    rule = "Host(`hass.lan.firecat53.net`)";
    service = "hass";
    middlewares = [ "headers" ];
    entrypoints = [ "websecure" ];
    tls = {
      certResolver = "le";
    };
  };
  services.traefik.dynamicConfigOptions.http.services.hass = {
    loadBalancer = {
      servers = [
        {
          url = "http://192.168.200.102:8123";
        }
      ];
    };
  };

  # Create thread.xml for SMLIGHT SLZB-07 Thread device. Used to attach/reattach to the VM
  environment.etc."thread.xml" = {
    text = ''
      <hostdev mode='subsystem' type='usb' managed='yes'>
          <source>
              <vendor id='0x10c4'/>
              <product id='0xea60'/>
          </source>
      </hostdev>
    '';
    target = "homeassistant/thread.xml";
  };
  # Create zbt2.xml for Zigbee ZBT-2 device. Used to attach/reattach to the VM
  environment.etc."zbt2.xml" = {
    text = ''
      <hostdev mode='subsystem' type='usb' managed='yes'>
          <source>
              <vendor id='0x303a'/>
              <product id='0x831a'/>
          </source>
      </hostdev>
    '';
    target = "homeassistant/zbt2.xml";
  };

  # Detach/reattach USB devices from the VM
  systemd.services.hass-usb-reattach = {
    description = "Reattach USB devices to hass VM";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "reattach-usb" ''
        #!/bin/sh
        # Wait for VM to fully start
        ${pkgs.coreutils}/bin/sleep 30
        if ${pkgs.libvirt}/bin/virsh list --name | grep -q "^hass$"; then
          ${pkgs.libvirt}/bin/virsh detach-device hass /etc/homeassistant/thread.xml
          ${pkgs.libvirt}/bin/virsh detach-device hass /etc/homeassistant/zbt2.xml
          ${pkgs.coreutils}/bin/sleep 5
          ${pkgs.libvirt}/bin/virsh attach-device hass /etc/homeassistant/thread.xml
          ${pkgs.libvirt}/bin/virsh attach-device hass /etc/homeassistant/zbt2.xml
        fi;
      '';
    };
  };
}
