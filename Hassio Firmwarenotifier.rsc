{
    global discoverypath "homeassistant/"
    global domainpath "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    global ID [/system/routerboard get serial-number] 
    #Name
    local Name [/system/identity/get name]
    #Model
    local Model [system/resource/get board-name] 
    #SW
    local CSW   [/system/package/get routeros version] 
    #Manufacturer
    global Manu [/system/resource/get platform] 

    #Get local IP address from bridge interface, and truncate prefix length
    local ipaddress [/ip/address/get [find interface=[/interface/bridge/get [/interface/bridge/find] name]] address ]
    :set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
    local urldomain [/ip/dns/static/ get [/ip/dns/static/ find address=$ipaddress name] name  ]
    if (urldomain != null) do={
        put "URL found"
        set ipaddress $urldomain
        }

    if (ipaddress != null) do={
        local url
        :if (! [/ip/service/get www-ssl disabled ]) \
            do={:set $url ",\"cu\":\"https://$ipaddress/\""} \
        else={if (! [/ip/service/get www disabled]) \
            do={:set $url ",\"cu\":\"http://$ipaddress/\""}}
        }
    #-------------------------------------------------------
    #Build device string
    #-------------------------------------------------------
    global dev "\"dev\":{\
        \"ids\":[\"$ID\"],\
        \"name\":\"$Name\",\
        \"mdl\":\"$Model\",\
        \"sw\":\"$CSW\",\
        \"mf\":\"$Manu\"$url}"

    global buildconfig do= {
        global discoverypath
        global domainpath
        global ID
        global dev

        #build config for Hassio
        local config "{\"~\":\"$discoverypath$domainpath$ID/$name\",\
            \"name\":\"$name\",\
            \"stat_t\":\"~/state\",\
            \"uniq_id\":\"$ID_$name\",\
            \"obj_id\":\"$ID_$name\",\
            $dev\
        }"
        /iot/mqtt/publish broker="Home Assistant" message=$config topic="$discoverypath$domainpath$ID/$name/config"               
    }
    global poststate do= {
        global discoverypath
        global domainpath
        global ID
        #post Routerboard firmware
        local state "{\"installed_version\":\"$cur\",\
            \"latest_version\":\"$new\"}"
        /iot/mqtt/publish broker="Home Assistant" message=$state topic="$discoverypath$domainpath$ID/$name/state"
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        $buildconfig name="RouterBOARD"

        #Get routerboard firmware
        local cur [/system/routerboard/ get current-firmware]
        local new [/system/routerboard/ get upgrade-firmware]

        #post Routerboard firmware
        $poststate name="RouterBOARD" cur=$cur new=$new
    }

    #-------------------------------------------------------
    #Handle RouterOS
    #-------------------------------------------------------
    $buildconfig name="RouterOS"

    #Get system software
    local cur [ /system/package/update/ get installed-version ]
    local new [ /system/package/update/ get latest-version ]

    $poststate name="RouterOS" cur=$cur new=$new

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

            $buildconfig name=$modemname
    
            #Get firmware version for LTE interface
            local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] once as-value ]
            local cur ($Firmware->"installed")
            local new ($Firmware->"latest")

            $poststate name=$modemname cur=$cur new=$new
            }
        }
    }
}