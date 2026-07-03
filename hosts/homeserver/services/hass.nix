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

  # Attach the Thread + Zigbee USB radios to the hass VM after boot.
  systemd.services.hass-usb-reattach = {
    description = "Attach USB radios to hass VM";
    after = [ "libvirtd.service" ];
    wantedBy = [ "libvirtd.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "reattach-usb" ''
        # Wait for the VM to be running (autostart may lag libvirtd by a few seconds).
        for _ in $(${pkgs.coreutils}/bin/seq 1 120); do
          [ "$(${pkgs.libvirt}/bin/virsh domstate hass 2>/dev/null)" = running ] && break
          ${pkgs.coreutils}/bin/sleep 1
        done

        # Clear any stale live attachment, then (re)attach. Retry the attach until the
        # host has enumerated the dongles
        ${pkgs.libvirt}/bin/virsh detach-device hass /etc/homeassistant/thread.xml 2>/dev/null || true
        ${pkgs.libvirt}/bin/virsh detach-device hass /etc/homeassistant/zbt2.xml 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 2
        for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
          ${pkgs.libvirt}/bin/virsh attach-device hass /etc/homeassistant/thread.xml && break
          ${pkgs.coreutils}/bin/sleep 1
        done
        for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
          ${pkgs.libvirt}/bin/virsh attach-device hass /etc/homeassistant/zbt2.xml && break
          ${pkgs.coreutils}/bin/sleep 1
        done
      '';
    };
  };
}
