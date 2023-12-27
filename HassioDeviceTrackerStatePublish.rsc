if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        local discoverypath "homeassistant/"
        local domainpath "device_tracker/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------
        #ID
        local ID [/system/routerboard get serial-number] 
        local pos [/system/gps/monitor once as-value]
        local data
        if (($pos->"valid")) do={
            set ($data->"latitude") ($pos->"latitude")
            set ($data->"longitude") ($pos->"longitude")
        } else={
            set ($data->"latitude") [:nothing]
            set ($data->"longitude") [:nothing]
        }
        set $data [serialize $data to=json]
        /iot/mqtt/publish broker="Home Assistant" message=$data topic="$discoverypath$domainpath$ID/attributes" retain=no   
    }
}