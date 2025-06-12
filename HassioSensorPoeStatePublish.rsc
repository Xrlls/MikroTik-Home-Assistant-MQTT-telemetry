:local discoverypath "homeassistant/"
:local domainpath "sensor/"
:local ID [/system/routerboard get serial-number] 
:local data
:foreach v in=[/interface/ethernet/poe monitor [find] once as-value] do={
    :local DefInterfaceValue [/interface/ethernet get [find name=($v->"name")] default-name]
    :set ($data->("x".$DefInterfaceValue)) ($v->"poe-out-current")
}
/iot/mqtt/publish broker="Home Assistant" message=[:serialize $data to=json] topic="$discoverypath$domainpath$ID/state_poe" retain=no