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
        #Build device string
        #-------------------------------------------------------
        local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
        local dev [$DeviceString]
        local buildconfig do= {
            local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
            local jsonname ("x".[$SearchReplace input=$name search="-" replace="_"])

            #build config for Hassio
           local entity
            set ($entity->"dev") $dev
            set ($entity->"name") ("$name"." POE")
            set ($entity->"stat_t") ("$discoverypath$domainpath".($entity->"dev"->"ids")."/state$NamePostfix")
            set ($entity->"uniq_id") (($entity->"dev"->"ids")."_$name$NamePostfix")
            set ($entity->"obj_id") ($entity->"uniq_id")
            set ($entity->"suggested_display_precision") 1
            set ($entity->"unit_of_measurement") $unit
            set ($entity->"dev_cla") "power"
            set ($entity->"value_template") "{{ (value_json.$jsonname/10)  | is_defined}}"
            set ($entity->"expire_after") 70
            /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
                topic=("$discoverypath$domainpath".($entity->"dev"->"ids")."/$name$NamePostfix/config") retain=yes        
        }
        foreach sensor in=[/interface/ethernet/poe/find] do={
            local name [/interface/ethernet/poe/get $sensor name];#name
            $buildconfig name=($name) unit=W NamePostfix="_poe" discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        }
    }
}