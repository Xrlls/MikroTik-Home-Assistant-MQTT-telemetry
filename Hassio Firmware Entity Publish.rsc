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
        local domainpath "update/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------

        local ID
        if ([pick [/system/resource/get board-name] 0 3] != "CHR") do={
        set ID [/system/routerboard get serial-number];#ID
        } else={
        set ID [system/license/get system-id ]
        }
        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
        local dev [$DeviceString]
        local buildconfig do= {

            #build config for Hassio
            local entity
            set ($entity->"\7E") "$discoverypath$domainpath$ID/$name"
            set ($entity->"name") $name
            set ($entity->"stat_t") "~/state"
            set ($entity->"uniq_id") "$ID_$name"
            set ($entity->"obj_id") "$ID_$name"
            set ($entity->"dev") $dev
            /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json] topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
        }
        #-------------------------------------------------------
        #Handle routerboard firmware for non CHR
        #-------------------------------------------------------
        if ([pick [/system/resource/get board-name] 0 3] != "CHR") do={
            $buildconfig name="RouterBOARD" ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        }

        #-------------------------------------------------------
        #Handle RouterOS
        #-------------------------------------------------------
        $buildconfig name="RouterOS" ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev

        #-------------------------------------------------------
        #Handle LTE interfaces
        #-------------------------------------------------------
        :foreach iface in=[/interface/lte/ find] do={
        local ifacename [/interface/lte get $iface name]

        #Get manufacturer and model for LTE interface
        local lte [ [/interface/lte/monitor [/interface/lte get $iface name] once as-value] manufacturer]
            if ($lte->"manufacturer"="\"MikroTik\"") do={
                {
                #build config for LTE
                local modemname [:pick ($lte->"model")\
                    ([:find ($lte->"model") "\"" -1] +1)\
                    [:find ($lte->"model") "\"" [:find ($lte->"model") "\"" -1]]]
                $buildconfig name=$modemname ID=$ID discoverypath=$discoverypath domainpath=$domainpath dev=$dev
                }
            }
        }
    }
}