# Use
# local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
# $DeviceString
#
local Device
local hwversion
local LowercaseHex [parse [system/script/get "HassioLib_LowercaseHex" source]]
# Get serial
if ([/system/resource/get board-name] != "CHR") do={
    set ($Device->"ids") [/system/routerboard get serial-number];#ID
    set $hw_version [[:parse "[system/routerboard/get revision]"]]
    if ([len $hwversion] >0) do={
        set ($Device->"hwversion") $hwversion
   }
} else={
    set ($Device->"ids") ("\"".[system/license/get system-id ]."\"")
}

set ($Device->"name") [/system/identity/get name];       #Name
set ($Device->"model") [system/resource/get board-name]; #Mode
set ($Device->"sw")   [/system/resource/get version ];  #SW
set ($Device->"mf") [/system/resource/get platform];   #Manufacturer

local index 0
# Get Ethernet MAC addresses
foreach iface in=[interface/ethernet/find ] do={
    set ($Device->"connections"->$index->0) "mac"
    set ($Device->"connections"->$index->1) [$LowercaseHex input=[/interface/ethernet/get $iface mac-address]]
    set $index ($index+1)
}

# Get Wi-Fi MAC addresses
if ([len [system/package/find name="wifiwave2"]]  =0 ) do={
    local Action [parse "local a [interface/wireless/get \$1 mac-address];return \$a"]
    foreach iface in=[[parse "/interface/wireless/ find interface-type!=\"virtual\""]] do={
        set ($Device->"connections"->$index->0) "mac"
        set ($Device->"connections"->$index->1) [$LowercaseHex input=[$Action $iface]]
        set $index ($index+1)
    }
}\
# Get Wi-Fi Wave2 MAC Addresses
else={
    local Action [parse "local a [/interface/wifiwave2/radio/get \$1 radio-mac];return \$a"]
    foreach iface in=[[parse "/interface/wifiwave2/radio/find"]] do={
        set ($Device->"connections"->$index->0) "mac"
        set ($Device->"connections"->$index->1) [$LowercaseHex input=[$Action $iface]]
        set $index ($index+1)
    }
}
# Find a reasonable link to WebFig if enabled.
local urldomain
local ipaddress

foreach bridge in=[/interface/bridge/find] do={
    foreach AddressIndex in=[ip/address/find where interface=[/interface/bridge/get $bridge name]] do={
        set ipaddress [/ip/address/get $AddressIndex address]
        set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
       foreach UrlIndex in=[/ip/dns/static/ find address=$ipaddress name] do={
            set $urldomain [/ip/dns/static/ get $UrlIndex name  ]
        }
    }
}
if ([len $ipaddress]=0) do={
    foreach addr in=[/ip/address/find] do={
        local TempAddress [/ip/address/get $addr address]
        set $TempAddress [:pick $TempAddress 0 [:find $TempAddress "/"]]
        foreach UrlIndex in=[/ip/dns/static/find address=$TempAddress] do={
            local TempUrlDomain [ip/dns/static/get $UrlIndex name]
            if ([len $TempUrlDomain]>0) do={set $urldomain $TempUrlDomain}
        }
    }
}
if ([len $urldomain]>0) do={set $ipaddress $urldomain}

local url
if ([len $ipaddress] >0) do={
    :if (! [/ip/service/get www-ssl disabled ]) \
        do={:set ($Device->"cu") "https://$ipaddress/"} \
    else={if (! [/ip/service/get www disabled]) \
        do={:set ($Device->"cu") "http://$ipaddress/"}}
}

return $Device