# Use
# local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
# $DeviceString
#
local ID
local LowercaseHex [parse [system/script/get "HassioLib_LowercaseHex" source]]
# Get serial
    if ([/system/resource/get board-name] != "CHR") do={
    set ID ("\"".[/system/routerboard get serial-number]."\"");#ID
    } else={
    set ID ("\"".[system/license/get system-id ]."\"")
    }

        local Name [/system/identity/get name];       #Name
        local Model [system/resource/get board-name]; #Mode
        local CSW   [/system/resource/get version ];  #SW
        local Manu [/system/resource/get platform];   #Manufacturer


# Get Ethernet MAC addresses
foreach iface in=[interface/ethernet/find ] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[/interface/ethernet/get $iface mac-address]].\
            "\"")
    if ([/interface/ethernet/get $iface mac-address] != [/interface/ethernet/get $iface orig-mac-address]) do= {
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[/interface/ethernet/get $iface orig-mac-address]].\
            "\"")
    }
}

# Get Wi-Fi MAC addresses
if ([len [system/package/find name="wifiwave2"]]  =0 ) do={
    local Condition [parse "local a [/interface/wireless/ find interface-type!=\"virtual\"];return \$a"]
    local Action [parse "local a [interface/wireless/get \$1 mac-address];return \$a"]
    foreach iface in=[$Condition] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[$Action $iface]].\
            "\"")
    }
}\
# Get Wi-Fi Wave2 MAC Addresses
else={
    local Condition [parse "local a [/interface/wifiwave2/radio/find];return \$a"]
    local Action [parse "local a [/interface/wifiwave2/radio/get \$1 radio-mac];return \$a"]
    foreach iface in=[$Condition] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[$Action $iface]].\
            "\"")
    }
}

if ( [len [/interface/bridge/find]]!= 0   ) do={ ; #check if [/interface/bridge/find]    is zero
put "Bridge found"
        #Get local IP address from bridge interface, and truncate prefix length
        local ipaddress [/ip/address/get [find interface=[/interface/bridge/get [/interface/bridge/find] name]] address ]
        :set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
        local urldomain [/ip/dns/static/ get [/ip/dns/static/ find address=$ipaddress name] name  ]
        if ([:typeof (urldomain)] != "nill") do={set ipaddress $urldomain}

        if ([:typeof (ipaddress)] != "nill") do={
            :if (! [/ip/service/get www-ssl disabled ]) \
                do={:set $url ",\"cu\":\"https://$ipaddress/\""} \
            else={if (! [/ip/service/get www disabled]) \
                do={:set $url ",\"cu\":\"http://$ipaddress/\""}}
            }
} else={
    put "Bridge not found"
    foreach addr in=[/ip/address/find] do={
        local temp [/ip/address/get $addr address]
        set $temp [:pick $temp 0 [:find $temp "/"]]
        set $temp [/ip/dns/static/find address=$temp]
        if ([len $temp] != 0) do={
        set $temp  [/ip/dns/static/get $temp name]
            :if (! [/ip/service/get www-ssl disabled ]) \
                do={:set $url ",\"cu\":\"https://$temp/\""} \
            else={if (! [/ip/service/get www disabled]) \
                do={:set $url ",\"cu\":\"http://$temp/\""}}
        }
    }
}
        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        global dev "\"dev\":{\
            \"ids\":[$ID],\
            \"name\":\"$Name\",\
            \"mdl\":\"$Model\",\
            \"sw\":\"$CSW\",\
            \"mf\":\"$Manu\"$url}"

#put $dev

return $dev