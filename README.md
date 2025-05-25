# MikroTik-Home-Assistant-MQTT-telemetry

I wrote this collection of scripts to enable telemetry from MikroTik RouterOS 7 based routers to Home Assistant through MQTT.

The background was that I wanted to be able to be notified when a new firmware upgrade was available without having to deal with the router itself.
## Functionality
The script monitors updates for RouterOS, RouterBOARD firmware, and any MikroTik LTE modem if present. Each of the firmware targets available are shown as separate entities in Home Assistant under a parent device. The JSON payload of the MQTT topics posted are all written to Home Assistant default to ensure that no configuration is required on Home Assistant.

If webfig is enabled, a bridge interface with an IP address, and optionally a static DNS entry for the address is created, a configuration link is shown in Home Assistant.

### Firmware update notifications
The script currently provides firmware update notifications for the following subsystems:
- RouterOS
- RouterBOARD (firmware)
- LTE modems
- NB/CAT-M modems (PPP attached)

### Health sensors
The script currently creates sensors in Home Assistant for whichever health sensors the routerboard has, typically voltage and temperature.

### Device Tracker (GPS/GNSS)
The script can report the Routerboards position to Home Assistant if equipped with a GPS/GNSS receiver.

### PoE monitoring
The script reports the current consumption on each PoE enabled port to Home Assistant.

### Bluetooth Beacons
The script adds Home Assistant Support for MikroTik Bluetooth beacons. It performs decoding of the beacon payload server side on Home Assistant, and adds device tracker functionality, registering whenever the device is present.
The device tracker uses GNSS positional data for the registered trackers if the MikroTik device has a. valid GPS position available, otherwise, the device is registered as `home` when in range.
The binary sensors on the MikroTik Bluetooth beacons are disabled by default from the factory, so no events will be showing in Home Assistant before they have been enabled using the companion app.

>[!IMPORTANT]
>Prerequisites
>- The beacons must be running in MikroTik format, and encryption must not be enabled.
>- The MikroTik router must be running 7.16 or newer.

>[!TIP]
>To reduce processor load, consider adding a whitelist policy similar to this:
>```
>/iot bluetooth scanners
>set bt1 disabled=no filter-policy=whitelist
>/iot bluetooth whitelist
>add address=D4:*:*:*:*:* address-type=public device=bt1
>add address=18:fd:*:*:*:* address-type=public device=bt1
>```
>The TG-BT5-OUT used for testing had a MAC beginning with `D4`, and the TG-BT5-IN used for testing was testing was starting with `18:FD`, but your mileage may vary.

### GPIOs
The script handles both Analog and Digital GPIOs, input and outputs. As GPIOs could be almost anything, they are in this context represented as 
- Voltmeters for analog inputs
- Binary sensors for digital inputs
- Switches for digital outputs

I only have a MikroTik KNOT available with GPIOs, so the support has not been widely tested, and the scripts will fairly certain fail if a device has only analog or digital GPIOs but not both. But I do not know if this config exists on a MikroTik device.

### UPS monitoring
The script currently reports various telemetry from connected UPS.
This has only been tested with a APC Back-UPS BX950, and the data it provides is not extensive compared to what the MikroTik documentation lists.
The documentation from Mikrotik is also lacking a bit, so your milage may vary. If seeing issues, reach out, and I will see what I can do.

## Security concerns

To reduce the attack surface for the router, these scripts do not subscribe to any topics on the MQTT server, hence it cannot be controlled from Home Assistant through these scripts.

## Tested devices
I have tested it on various MikroTik devices I have available:
- RB5009UPr+S+
- wAP ac LTE6 kit aka. wAP R ac
- hAP ax^2
- CHR
- SXTsq Lite2 (no longer tested)
- L009UiGS-2HaxD-IN
- KNOT LR8 aka. KNOT R
- SXT LTE kit aka. SXT R

I will happily test on any other devices you might want to gift me :)

### Community tested devices
These are devices reported as working by others, but I don't own myself:
- RB450Gx4 reported by [SkeLLLa](https://github.com/SkeLLLa) on April 26<sup>th</sup>, 2025
- CRS328-24P-4S+ reported by [SkeLLLa](https://github.com/SkeLLLa) on April 26<sup>th</sup>, 2025

## Installation

### MQTT setup
#### Home Assistant
Home Assistant needs to have:
- The MQTT integration must be installed
- There must be a connection to (the same) MQTT server as you intend to connect the router to.
The details of this is not covered in this guide.

### RouterOS
The IOT packages needs to be installed. The installation is not covered in this guide.

When the package is installed, a connection needs to be configured to Home Assistant.
```
/iot mqtt brokers add address=<MQTT server IP> auto-connect=yes name="Home Assistant" password=<password> username=<username>
```
The scripts currently depends on the name of the broker being `Home Assistant`. `auto-connect` is set to `yes` as the scripts do not handle setting up the initial connection themselves.

I have found that this only works with IPv4 addresses and domain names. I have not had luck with IPv6.

>[!NOTE]
>If connecting multiple routers through MQTT, it is very important that they each have a unique `client-id`. If the client IDs are not unique, the broker, such as Mosquitto, will disconnect the clients. The `client-id` is by default `MT`.
>The client ID can be set to the routerboard serial number like this (for non-CHR devices):
>```
>/iot/mqtt/brokers/set [find name="Home Assistant"] client-id=[/system/routerboard/get serial-number]
>```

### Script Installation
Run the command below from the terminal:
```
[[:parse ([/tool/fetch https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioInstaller.rsc output=user as-value ]->"data")]]
```
