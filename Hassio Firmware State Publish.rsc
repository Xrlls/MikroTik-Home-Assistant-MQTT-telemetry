{
    global discoverypath "homeassistant/"
    global domainpath "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    global ID [/system/routerboard get serial-number] 

    global poststate do= {
        global discoverypath
        global domainpath
        global ID
        #post Routerboard firmware
        local state "{\"installed_version\":\"$cur\",\
            \"latest_version\":\"$new\",\
            \"rel_u\":\"https://mikrotik.com/download/changelogs\"}"
        /iot/mqtt/publish broker="Home Assistant" message=$state topic="$discoverypath$domainpath$ID/$name/state" retain=yes
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        #Get routerboard firmware
        local cur [/system/routerboard/ get current-firmware]
        local new [/system/routerboard/ get upgrade-firmware]

        #post Routerboard firmware
        $poststate name="RouterBOARD" cur=$cur new=$new
    }

    #-------------------------------------------------------
    #Handle RouterOS
    #-------------------------------------------------------
    #Get system software
    system/package/update/check-for-updates
    :delay 5s
    local cur [ /system/package/update/ get installed-version ]
    local new [ /system/package/update/ get latest-version ]

        #Get release note:
        /tool/fetch "http://upgrade.mikrotik.com/routeros/$new/CHANGELOG"
              #            http://upgrade.mikrotik.com/routeros/7.12beta7/CHANGELOG
        :delay 5s
        global test [/file/get "CHANGELOG" contents]
        :put [$test]
        :put [:len  $test]
        :set test [:pick $test -1 255]
        #Text must be escaped before posting as JSON!
        :put [$test]
        :put [:len  $test]

    $poststate name="RouterOS" cur=$cur new=$new

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
    
            #Get firmware version for LTE interface
            local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] once as-value ]
            local cur ($Firmware->"installed")
            local new ($Firmware->"latest")

            $poststate name=$modemname cur=$cur new=$new
            }
        }
    }
}