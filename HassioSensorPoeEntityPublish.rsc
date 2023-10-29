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
        local domainpath "sensor/"

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
            local config ("{\"name\":\"$name"." POE"."\",\
                \"stat_t\":\"$discoverypath$domainpath$ID/state$NamePostfix\",\
                \"uniq_id\":\"$ID_$name$NamePostfix\",\
                \"obj_id\":\"$ID_$name$NamePostfix\",\
                \"suggested_display_precision\": 1,\
                \"unit_of_measurement\": \"$unit\",\
                \"value_template\": \"{{ value_json.$jsonname | is_defined}}\",\
                \"expire_after\":70,\
                $dev\
            }")
            /iot/mqtt/publish broker="Home Assistant" message=$config topic=("$discoverypath$domainpath$ID/$name$NamePostfix/config") retain=yes        
        }
        foreach sensor in=[/interface/ethernet/poe/find] do={
            local name [/interface/ethernet/poe/get $sensor name];#name
            $buildconfig name=($name) unit=W NamePostfix="_poe" ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        }
    }
}