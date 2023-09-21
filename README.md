# MikroTik-Home-Assistant-MQTT-telemetry

I wrote this code to enable telemetry from MikroTik RouterOS 7 based routers to Home Assistant through MQTT.

The background was that I wanted to be able to be notified when a new firmware upgrade was available without having to deal with the router itself.

The script monitors updates for RouterOS, RouterBOARD firmware, and any MikroTik LTE modem if present. Each of the firmware targets available are shown as separate entities in Home Assistant under a parent device. The JSON payload of the MQTT topics posted are all written to Home Assistant default to ensure that no configuration is required on Home Assistant.

If webfig is enabled, a bridge interface with an IP address, and optionally a static DNS entry for the address is created, a configuration link is shown in Home Assistant.

## Tested devices
I have tested it on various MikroTik devices I have available:
- RB5009
- wAP R ac
- wAP ax^2
- CHR

I will happily test on any other devices you might want to gift me :)

## Installation

### MQTT setup
#### Home Assistant

### RouterOS
The IOT packages needs to be installed. The installation is not covered in this guide.

When the package is installed, a connection needs to be configured to Home Assistant.
  /iot mqtt brokers
  add address=\<MQTT server IP\> auto-connect=yes name="Home Assistant" password=\<password\> username=\<username\>
The scripts currently depends on the name of the broker being <Home Assistant>. <auto-connect> is set to <yes> as the scripts do not handle setting up the initial connection themselves.



### Script Installation
