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
            local entity
            set ($entity->"name") $name
            set ($entity->"stat_t") "$discoverypath$domainpath$ID/state"
            set ($entity->"uniq_id") "$ID_$name"
            set ($entity->"obj_id") "$ID_$name"
            set ($entity->"suggested_display_precision") 1
            set ($entity->"unit_of_measurement") $unit
            set ($entity->"value_template") "{{ value_json.$jsonname }}"
            set ($entity->"expire_after") 70
            set ($entity->"dev") $dev
            /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json] topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
        }
        foreach sensor in=[/system/health/find] do={
            local name [/system/health/get $sensor name];#name
            local unit [/system/health/get $sensor type];#unit
            if ($unit="C") do={set $unit "\C2\B0\43"}
            $buildconfig name=$name unit=$unit ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        }
    }
}