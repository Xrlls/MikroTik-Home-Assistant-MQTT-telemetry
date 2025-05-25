:local discoverypath "homeassistant/"
:local domainpath "device"

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
        :local migrate false
        :if [/system/scheduler/find name~"^Hassio.+EntityPublish\$"] do={
            :set migrate true
            :put "Migrating to device based discovery..."
        }
        /system/script
        :local out
        :local temp
        :foreach script in=[find name~"^Hassio.*EntityPublish\$" and !(name~"^HassioLib")] do={
            :set temp ($out->"cmps");                   #Storing existing components
            :set out [[:parse [get $script source]]];   #Run code to add new components
            :set ($out->"cmps") (($out->"cmps"),$temp); #Concatenating existing and neww components
        }

        :log debug [:serialize to=json $out]

        :local topics
        #Migrate topics
        :if $migrate do={
            :log info "Start migration..."
            :foreach entity,params in=($out->"cmps") do={
                :set ($topics->$entity) ($discoverypath.($params->"p")."/".($out->"dev"->"sn")."/".$entity."/config")
                :log debug ($topics->$entity)
                /iot/mqtt/publish broker="Home Assistant" topic=($topics->$entity) message="{\"migrate_discovery\": true }"
            }
        }

        #Publish device
        :log info "Publish device..."
        /iot/mqtt/publish broker="Home Assistant" topic=($discoverypath.$domainpath."/".($out->"dev"->"sn")."/config")\
            message=[:serialize to=json $out]\
            retain=yes

        #Migrate complete
        :if ($migrate) do={
            :log info "Completing migration..."
            :foreach ctopic in=$topics do={
                :log debug $ctopic
                /iot/mqtt/publish broker="Home Assistant" topic=$ctopic message="" retain=yes; #Message must be retained or Home Assistant throws a persistant error.

            }
            :log info "removing entity publish schedulers..."
            /system/scheduler/remove [find name~"^Hassio.+EntityPublish\$"]
        }
        :set migrate
    }
}