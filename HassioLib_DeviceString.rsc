# Use
# local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
# $DeviceString
#
local Device
local hwversion
# Get serial
if (!([/system/resource/get board-name ]~"^CHR")) do={
    set ($Device->"dev"->"ids") [/system/routerboard get serial-number];#ID
    set ($Device->"dev"->"sn") ($Device->"dev"->"ids")
    set $hwversion [[:parse "[system/routerboard/get revision]"]]
    if ([len $hwversion] >0) do={
        set ($Device->"dev"->"hw") $hwversion
   }
} else={
    set ($Device->"dev"->"ids") [system/license/get system-id ]
}
set ($Device->"dev"->"name") [/system/identity/get name];     #Name
set ($Device->"dev"->"mdl") [system/resource/get board-name]; #Mode
set ($Device->"dev"->"sw")   [/system/resource/get version ]; #SW
set ($Device->"dev"->"mf") [/system/resource/get platform];   #Manufacturer

local index 0
# Get Ethernet MAC addresses
foreach iface in=[interface/ethernet/find ] do={
    set ($Device->"dev"->"cns"->$index->0) "mac"
    set ($Device->"dev"->"cns"->$index->1) [convert transform=lc [/interface/ethernet/get $iface mac-address]]
    set $index ($index+1)
}
# Get Wi-Fi MAC addresses
    local iface
    :onerror ErrorName in={set iface [[parse "/interface/wireless/ find interface-type!=\"virtual\""]]} do={set iface [:nothing]; log/info message="no wireless"}
    local Action [parse "local a [interface/wireless/get \$1 mac-address];return \$a"]
    foreach ciface in=$iface do={
        set ($Device->"dev"->"cns"->$index->0) "mac"
        set ($Device->"dev"->"cns"->$index->1) [convert transform=lc [$Action $ciface]]
        set $index ($index+1)
    }
# Get Wi-Fi Wave2 MAC Addresses
    :onerror ErrorName in={set iface [[parse "/interface/wifiwave2/radio/find"]]} do={set iface [:nothing]; log/info message="no WIFI wave2"}
    local Action [parse "local a [/interface/wifi/radio/get \$1 radio-mac];return \$a"]
    foreach ciface in=$iface do={
        set ($Device->"dev"->"cns"->$index->0) "mac"
        set ($Device->"dev"->"cns"->$index->1) [convert transform=lc [$Action $ciface]]
        set $index ($index+1)
    }

# Find a reasonable link to WebFig if enabled.
local ipaddress
foreach bridge in=[/interface/bridge/find] do={
    foreach AddressIndex in=[ip/address/find where interface=[/interface/bridge/get $bridge name] and disabled=no] do={
        set ipaddress [/ip/address/get $AddressIndex address]
        set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
        do {set $ipaddress [resolve $ipaddress]
            set $ipaddress [pick $ipaddress 0 ([len $ipaddress]-1)]}\
        on-error={}
    }
}
if ([len $ipaddress]=0) do={
    foreach addr in=[/ip/address/find disabled=no] do={
        local TempAddress [/ip/address/get $addr address]
        set $TempAddress [:pick $TempAddress 0 [:find $TempAddress "/"]]
        do {set $ipaddress [resolve $TempAddress]
            set $ipaddress [pick $ipaddress 0 ([len $ipaddress]-1)]}\
        on-error={}
    }
}

if ([len $ipaddress] >0) do={
    :if (! [/ip/service/get www-ssl disabled ]) \
        do={:set ($Device->"dev"->"cu") "https://$ipaddress/"} \
    else={if (! [/ip/service/get www disabled]) \
        do={:set ($Device->"dev"->"cu") "http://$ipaddress/"}}
}
:set ($Device->"o"->"name") "MikroTik-Home-Assistant-MQTT-telemetry"
:set ($Device->"o"->"url") "https://github.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry"

return $Device