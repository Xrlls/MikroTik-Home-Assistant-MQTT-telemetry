if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        local Ctr 0
        while ((![/iot/mqtt/brokers/get [/iot/mqtt/brokers/find name="Home Assistant"] connected ])&&(Ctr<12)) do={ ;# If Home assistant broker is not connected
            log/info message="HassioMQTT: Broker not connected reattempting connection..."
            delay 1m; # Wait and attempt reconnect
            set $Ctr ($Ctr+1)
            iot/mqtt/connect broker="Home Assistant"
        }
        local discoverypath "homeassistant/"
        local domainpath "update/"

        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------
        #ID
        local ID
            if ([/system/resource/get board-name] != "CHR") do={
        set ID [/system/routerboard get serial-number];#ID
        } else={
            set ID [system/license/get system-id ]
        }

        local poststate do= {
            if ((typeof $url)!=nil) do={
            set $url  ",\"release_url\":\"$url\""
            }

            if ((typeof $note)!=nil) do={
            set $note ",\"release_summary\":\"$note\""
            }

            local state "{\"installed_version\":\"$cur\",\
                \"latest_version\":\"$new\"$url$note}"
            /iot/mqtt/publish broker="Home Assistant" message=$state topic="$discoverypath$domainpath$ID/$name/state" retain=yes
        }
        #-------------------------------------------------------
        #Handle routerboard firmware for non CHR
        #-------------------------------------------------------
        if ([/system/resource/get board-name] != "CHR") do={
            #Get routerboard firmware
            local Act [parse "/system/routerboard/get current-firmware"]
            local cur [$Act]
            local Act [parse "/system/routerboard/get upgrade-firmware"]
            local new [$Act]
            #post Routerboard firmware
            $poststate name="RouterBOARD" cur=$cur new=$new ID=$ID discoverypath=$discoverypath domainpath=$domainpath
        }

        #-------------------------------------------------------
        #Handle RouterOS
        #-------------------------------------------------------
        #Get system software
        local versions [/system/package/update/check-for-updates as-value ]

        local cur ($versions->"installed-version")
        local new ($versions->"latest-version")

        #Get release note:
        local test ([/tool/fetch "http://upgrade.mikrotik.com/routeros/$new/CHANGELOG" output=user as-value]->"data")

        :set test [:pick $test -1 255]

        #Text must be escaped before posting as JSON!
        local JsonEscape [parse [system/script/get "HassioLib_JsonEscape" source]]
        set $test [$JsonEscape input=$test]

        local JsonPick [parse [system/script/get "HassioLib_JsonPick" source]]
        set $test [$JsonPick input=$test len=255]

        local urls {development="https://mikrotik.com/download/changelogs/development-release-tree";\
            long-term="https://mikrotik.com/download/changelogs/long-term-release-tree";\
            stable="https://mikrotik.com/download/changelogs/stable-release-tree";\
            testing="https://mikrotik.com/download/changelogs/testing-release-tree"}
        set urls ($urls->[system/package/update/get channel ])

        $poststate name="RouterOS" cur=$cur new=$new url=$urls note=$test ID=$ID discoverypath=$discoverypath domainpath=$domainpath

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

                #Get firmware version for LTE interface
                local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] once as-value ]
                local cur ($Firmware->"installed")
                local new ($Firmware->"latest")

                $poststate name=$modemname cur=$cur new=$new ID=$ID discoverypath=$discoverypath domainpath=$domainpath
                }
            }
        }
    }
}