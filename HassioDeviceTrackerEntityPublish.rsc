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
        local domainpath "device_tracker"

        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local dev [[parse [system/script/get "HassioLib_DeviceString" source]]]
        local buildconfig do= {
            local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
            local jsonname ("x".[$SearchReplace input=$name search="-" replace="_"])

            #build config for Hassio
            local entity
            set $entity ($entity,$dev)
            :set ($entity->"cmps"->$name->"p") $domainpath
            set ($entity->"cmps"->$name->"name") $name
            set ($entity->"cmps"->$name->"uniq_id") (($entity->"dev"->"ids")."_$name")
            set ($entity->"cmps"->$name->"obj_id") ($entity->"uniq_id")
            set ($entity->"cmps"->$name->"~") ("$discoverypath$domainpath/".($entity->"dev"->"ids")."/attributes")
            set ($entity->"cmps"->$name->"json_attr_t") "~"
            set ($entity->"cmps"->$name->"avty_t") "~"
            set ($entity->"cmps"->$name->"src_type") "gps"
            set ($entity->"cmps"->$name->"avty_tpl") "\
                {%if value_json.latitude is defined and value_json.longitude is defined%}\
                    {{'online'}}\
                {%else%}\
                    {{'offline'}}\
                {%endif%}"            
            #/iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
            #    topic=("$discoverypath$domainpath".($entity->"dev"->"ids")."/$name/config") retain=yes              
            :return $entity;#[:serialize to=json $entity]
        }
            local name "GPS";#name
            :return [$buildconfig name=$name discoverypath=$discoverypath domainpath=$domainpath dev=$dev]
    }
}