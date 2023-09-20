{
    :local discovery_path "homeassistant/"
    :local domain_path "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    local ID [/system/routerboard get serial-number] 
    #Name
    local Name [/system/identity/get name]
    #Model
    local Model [system/resource/get board-name] 
    #SW
    local CSW   [/system/package/get routeros version] 
    #Manufacturer
    local Manu [/system/resource/get platform] 

    #Get local IP address from bridge interface, and truncate prefix length
    local ipaddress [/ip/address/get [find interface="bridge"] address ]
    :set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]

    local url
    :if (! [/ip/service/get www-ssl disabled ]) \
        do={:set $url ",\"cu\":\"https://$ipaddress/\""} \
    else={if (! [/ip/service/get www disabled]) \
        do={:set $url ",\"cu\":\"http://$ipaddress/\""}}

    #-------------------------------------------------------
    #Build device string
    #-------------------------------------------------------
    local dev "\"dev\":{\
        \"ids\":[\"$ID\"],\
        \"name\":\"$Name\",\
        \"mdl\":\"$Model\",\
        \"sw\":\"$CSW\",\
        \"mf\":\"$Manu\"$url}"

    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={

        #build config for Hassio
        local config "{\"~\":\"homeassistant/update/$ID/routerboard\",\
            \"name\":\"RouterBOARD\",\
            \"stat_t\":\"~/state\",\
            \"uniq_id\":\"$ID_routerboard\",\
            \"obj_id\":\"$ID_routerboard\",\
            $dev\
            }"

        /iot/mqtt/publish broker="Home Assistant" message=$config topic="homeassistant/update/$ID/routerboard/config"

        #Get routerboard firmware
        local cur [/system/routerboard/ get current-firmware]
        local new [/system/routerboard/ get upgrade-firmware]

        #post Routerboard firmware
        local state "{\"installed_version\":\"$cur\",\
            \"latest_version\":\"$new\"}"

        /iot/mqtt/publish broker="Home Assistant" message=$state topic="homeassistant/update/$ID/routerboard/state"

    }

    #-------------------------------------------------------
    #HAndle RouterOS
    #-------------------------------------------------------
    #build config for Hassio
    local config "{\"~\":\"homeassistant/update/$ID/routerOS\",\
        \"name\":\"RouterOS\",\
        \"stat_t\":\"~/state\",\
        \"uniq_id\":\"$ID_routerOS\",\
        \"obj_id\":\"$ID_routerOS\",\
        $dev\
        }"
    /iot/mqtt/publish broker="Home Assistant" message=$config topic="homeassistant/update/$ID/routerOS/config"

    #Get system software
    local cur [ /system/package/update/ get installed-version ]
    local new [ /system/package/update/ get latest-version ]

    local state "{\"installed_version\":\"$cur\",\
    \"latest_version\":\"$new\"}"

    /iot/mqtt/publish broker="Home Assistant" message=$state topic="homeassistant/update/$ID/routerOS/state"

    #-------------------------------------------------------
    #Handle LTE interfaces
    #-------------------------------------------------------
    #Count nummer of LTE interfaces

    :foreach iface in=[/interface/lte/ find] do={
    local ifacename [/interface/lte get $iface name]

    #Get manufacturer and model for LTE interface
    global lte [ [/interface/lte/monitor [/interface/lte get $iface name] once as-value] manufacturer]
        if ($lte->"manufacturer"="\"MikroTik\"") do={
            {
            #build config for LTE
            local modemname [:pick ($lte->"model")\
                ([:find ($lte->"model") "\"" -1] +1)\
                [:find ($lte->"model") "\"" [:find ($lte->"model") "\"" -1]]]

            local config "{\"~\":\"homeassistant/update/$ID/$ifacename\",\
                \"name\":\"$modemname\",\
                \"stat_t\":\"~/state\",\
                \"uniq_id\":\"$ID_$ifacename\",\
                \"obj_id\":\"$ID_$ifacename\",\
                $dev\
                }"

            /iot/mqtt/publish broker="Home Assistant" message=$config topic="homeassistant/update/$ID/$ifacename/config"
        
            #Get firmware version for LTE interface
            local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] once as-value ]
            local cur ($Firmware->"installed")
            local new ($Firmware->"latest")

            local state "{\
                \"installed_version\":\"$cur\",\
                \"latest_version\":\"$new\"}"

            /iot/mqtt/publish broker="Home Assistant" message=$state topic="homeassistant/update/$ID/$ifacename/state"
            }
        }
    }
}