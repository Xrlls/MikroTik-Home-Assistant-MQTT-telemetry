{
    global discoverypath "homeassistant/"
    global domainpath "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    global ID [/system/routerboard get serial-number];#ID
    { 
        local Name [/system/identity/get name];       #Name
        local Model [system/resource/get board-name]; #Mode
        local CSW   [/system/resource/get version ];  #SW
        local Manu [/system/resource/get platform];   #Manufacturer

        #Get local IP address from bridge interface, and truncate prefix length
        local ipaddress [/ip/address/get [find interface=[/interface/bridge/get [/interface/bridge/find] name]] address ]
        :set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
        local urldomain [/ip/dns/static/ get [/ip/dns/static/ find address=$ipaddress name] name  ]
        if ([:typeof (urldomain)] != "nill") do={set ipaddress $urldomain}

        local url
        if ([:typeof (ipaddress)] != "nill") do={
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
    }
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
        /iot/mqtt/publish broker="Home Assistant" message=$config topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        $buildconfig name="RouterBOARD"
    }

    #-------------------------------------------------------
    #Handle RouterOS
    #-------------------------------------------------------
    $buildconfig name="RouterOS"

    #-------------------------------------------------------
    #Handle LTE interfaces
    #-------------------------------------------------------
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
            }
        }
    }
}