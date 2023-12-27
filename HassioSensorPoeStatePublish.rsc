local discoverypath "homeassistant/"
local domainpath "sensor/"
local ID [/system/routerboard get serial-number] 
local data
foreach iface in=[/interface/ethernet/poe/ find] do={
    local InterfaceName [/interface/ethernet/poe/get $iface name]
    local InterfaceValue [interface/ethernet/poe/monitor $iface once as-value ]
    if ([:len ($InterfaceValue->"poe-out-current")]=0) do={set ($InterfaceValue->"poe-out-current") [:nothing]}
    set ($data->("x".[/interface/ethernet/poe/get $iface name])) ($InterfaceValue->"poe-out-current")
}
/iot/mqtt/publish broker="Home Assistant" message=[:serialize $data to=json] topic="$discoverypath$domainpath$ID/state_poe" retain=no