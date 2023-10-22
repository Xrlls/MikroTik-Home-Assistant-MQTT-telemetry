local discoverypath "homeassistant/"
local domainpath "sensor/"
local ID [/system/routerboard get serial-number] 

local Out "{"

foreach iface in=[/interface/ethernet/poe/ find] do={
    local InterfaceName [/interface/ethernet/poe/get $iface name]
    local InterfaceValue [interface/ethernet/poe/monitor $iface once as-value ]
    if ([:len ($InterfaceValue->"poe-out-current")]=0) do={set ($InterfaceValue->"poe-out-current") 0}
    set $Out ($Out."\"x$InterfaceName\":".\
    [([:tonum [($InterfaceValue->"poe-out-current")]]/10) ].\
    ".".\
    ([:tonum [($InterfaceValue->"poe-out-current")]]%10).\
    ",")
}
set $Out ([pick $Out -1 ([len $Out]-1)]."}")
/iot/mqtt/publish broker="Home Assistant" message=$Out topic="$discoverypath$domainpath$ID/state_poe" retain=no