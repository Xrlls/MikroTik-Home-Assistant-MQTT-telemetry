local discoverypath "homeassistant/"
local domainpath "sensor/"
local ID [/system/routerboard get serial-number] 
local data

/iot/gpio/analog
:foreach gpio in=[find] do={
    :set ($data->("x".[get $gpio name])) [get $gpio value]
}


/iot/gpio/digital
:foreach gpio in=[find] do={
    :if ([get $gpio direction]="input") do={
        :set ($data->("x".[get $gpio name])) [:tobool [:tonum [get $gpio input]]]
    } else={
        :set ($data->("x".[get $gpio name])) [:tobool [:tonum [get $gpio output]]]
    }
}

#:put [:serialize $data to=json]

/iot/mqtt/publish broker="Home Assistant" message=[:serialize $data to=json] topic="$discoverypath$domainpath$ID/state_GPIO" retain=no