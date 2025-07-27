if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        :local discoverypath "homeassistant/"
        :local domainpath "device/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------
        #ID
        :local ID
        if (!([/system/resource/get board-name ]~"^CHR")) do={
            :set ID [/system/routerboard get serial-number];#ID
        } else={
            :set ID [system/license/get system-id ]
        }

        :local data
        :local sensors ({"uptime";"cpu-load";"free-memory";"free-hdd-space"})
        :local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
        :foreach sensor in=$sensors do={
            set ($data->("x".[$SearchReplace input=$sensor search="-" replace="_"])) [:tonum [/system/resource/get $sensor]]
        }
        :set $data [serialize $data to=json]
        /iot/mqtt/publish broker="Home Assistant" message=$data topic="$discoverypath$domainpath$ID/resource" retain=no
    }
}