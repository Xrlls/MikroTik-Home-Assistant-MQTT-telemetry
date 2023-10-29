if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        local discoverypath "homeassistant/"
        local domainpath "sensor/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------
        #ID
        local ID [/system/routerboard get serial-number] 

        local string "{"
        local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
        foreach sensor in=[/system/health/find] do={
            set $string (($string).("\"").\
                ("x").([$SearchReplace input=[/system/health/get $sensor name] search="-" replace="_"]).("\":").\
                ([/system/health/get $sensor value]).(","))
        }
        set $string ([pick $string -1 ([len $string ]-1)]."}")
        
        /iot/mqtt/publish broker="Home Assistant" message=$string topic="$discoverypath$domainpath$ID/state" retain=no   
    }
}