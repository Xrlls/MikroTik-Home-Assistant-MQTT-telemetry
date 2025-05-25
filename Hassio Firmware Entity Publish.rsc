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
        local domainpath "update"

        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local dev [[parse [system/script/get "HassioLib_DeviceString" source]]]
        local buildconfig do= {
            :local entity
            :set $entity ($entity,$dev)
            :foreach k,v in=$name do={
                #build config for Hassio
                :set ($entity->"cmps"->$k->"p") $domainpath
                set ($entity->"cmps"->$k->"\7E") ("$discoverypath$domainpath/".($entity->"dev"->"ids")."/$k")
                set ($entity->"cmps"->$k->"name") $k
                set ($entity->"cmps"->$k->"stat_t") "~/state"
                set ($entity->"cmps"->$k->"uniq_id") (($entity->"dev"->"ids")."_$k")
                set ($entity->"cmps"->$k->"obj_id") ($entity->"uniq_id")
            }
            :return $entity
#            :put [:serialize to=json $entity]
#            /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
#                topic=("$discoverypath$domainpath".($entity->"dev"->"ids")."/$name/config") retain=yes
            
        }
        :local all
        #-------------------------------------------------------
        #Handle routerboard firmware for non CHR
        #-------------------------------------------------------
        if (!([/system/resource/get board-name ]~"^CHR")) do={
            #$buildconfig name="RouterBOARD" discoverypath=$discoverypath domainpath=$domainpath dev=$dev
            :set ($all->"RouterBOARD") [:nothing]
        }

        #-------------------------------------------------------
        #Handle RouterOS
        #-------------------------------------------------------
        #$buildconfig name="RouterOS" discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        :set ($all->"RouterOS") [:nothing]

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
                #$buildconfig name=$modemname discoverypath=$discoverypath domainpath=$domainpath dev=$dev
                :set ($all->$modemname) [:nothing]
                }
            }
        }

        #-------------------------------------------------------
        #Handle NB/CAT-M interfaces
        #-------------------------------------------------------
        /interface/ppp-client/
        :foreach i in=[find] do={
            :local upd [firmware-upgrade $i as-value]
            :local inf
            :if (($upd->"status")!="Failed!") do={
                :do {:set  inf [info $i once as-value]} on-error={}
            }
            :if ([:len $inf]!=0) do={
                :if (($inf->"model")~"AT\\+GMM") do={
                    :set ($inf->"model") [:pick ($inf->"model") 6 [:len ($inf->"model")]];
                    #:put "AT command"
                }
                #$buildconfig name=($inf->"model") discoverypath=$discoverypath domainpath=$domainpath dev=$dev
                :set ($all->($inf->"model")) [:nothing]
            }
        }
#        :put $all        
        :return [$buildconfig name=$all discoverypath=$discoverypath domainpath=$domainpath dev=$dev]
    }
}