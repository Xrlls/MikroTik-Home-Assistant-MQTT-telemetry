:local discoverypath "homeassistant/"
:local domainpath "sensor/"
:local ID [/system/routerboard get serial-number] 
:local data
:local NoInt [:len [/interface/ethernet/poe/ find]]; #Find number of PoE interfaces
:local val [/interface/ethernet/poe monitor [find] once as-value]
:local vIn
:if ($NoInt=1) do={;#Handle cases with a single PoE capable port.
    :log debug "Found single"
    :set ($vIn->0) $val
} else={;#Handle cases with more PoE capable ports.
    :log debug "Found more"
    :set $vIn $val 
}
:foreach v in=$vIn do={
    :local DefInterfaceValue [/interface/ethernet get [find name=($v->"name")] default-name]
    :set ($data->("x".$DefInterfaceValue)) ($v->"poe-out-power")
}
/iot/mqtt/publish broker="Home Assistant" message=[:serialize $data to=json] topic="$discoverypath$domainpath$ID/state_poe" retain=no