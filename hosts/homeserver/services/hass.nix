# Home Assistant - VM behind Traefik
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

  # Create conbee.xml for Conbee II Zigbee device. Used to attach/reattach to the VM
  environment.etc."conbee.xml" = {
    text = ''
      <serial type='dev'>
        <source path='/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2420510-if00'/>
        <target type='usb-serial' port='1'>
          <model name='usb-serial'/>
        </target>
        <alias name='serial1'/>
        <address type='usb' bus='0' port='4'/>
      </serial>
    '';
    target = "homeassistant/conbee.xml";
  };
}
