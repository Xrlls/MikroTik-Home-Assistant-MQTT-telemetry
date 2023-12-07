if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        while (![/iot/mqtt/brokers/get [/iot/mqtt/brokers/find name="Home Assistant"] connected ]) do={ ;# If Home assistant broker is not connected
            log/info message="HassioMQTT: Broker not connected reattempting connection..."
            delay 1m; # Wait and attempt reconnect
            iot/mqtt/connect broker="Home Assistant"
        }

        local discoverypath "homeassistant/"
        local domainpath "device_tracker/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------

        local ID [/system/routerboard get serial-number];#ID

        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
        local dev [$DeviceString]
        local buildconfig do= {
            local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
            local jsonname ("x".[$SearchReplace input=$name search="-" replace="_"])

            #build config for Hassio
            local config "{\"name\":\"$name\",\
                \"uniq_id\":\"$ID_$name\",\
                \"obj_id\":\"$ID_$name\",\
                \"json_attributes_topic\":\"$discoverypath$domainpath$ID/attributes\",\
                \"source_type\":\"gps\",\
                $dev\
            }"
            /iot/mqtt/publish broker="Home Assistant" message=$config topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
        }
            local name "GPS";#name
            $buildconfig name=$name ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev
    }
}