:local discoverypath "homeassistant/"
:local domainpath "sensor/"
:local ID [/system/routerboard get serial-number] 
:local data
:foreach iface in=[/interface/ethernet/poe/ find] do={
    :local InterfaceName [/interface/ethernet/poe/get $iface name]; #Friendly name
    :local DefInterfaceValue [/interface/ethernet get [find name=$InterfaceName] default-name]
    :local InterfaceValue [/interface/ethernet/poe/monitor $iface once as-value ]
    :set ($data->("x".$DefInterfaceValue)) ($InterfaceValue->"poe-out-current")
}
/iot/mqtt/publish broker="Home Assistant" message=[:serialize $data to=json] topic="$discoverypath$domainpath$ID/state_poe" retain=no