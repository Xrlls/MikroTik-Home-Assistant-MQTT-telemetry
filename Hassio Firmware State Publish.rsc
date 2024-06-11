if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        local Ctr 0
        while ((![/iot/mqtt/brokers/get [/iot/mqtt/brokers/find name="Home Assistant"] connected ])&&($Ctr<12)) do={ ;# If Home assistant broker is not connected
            log/info message="HassioMQTT: Broker not connected reattempting connection..."
            delay 1m; # Wait and attempt reconnect
            set $Ctr ($Ctr+1)
            iot/mqtt/connect broker="Home Assistant"
        }
        local discoverypath "homeassistant/"
        local domainpath "update/"
        :global HassioReleaseNote
        #-------------------------------------------------------
        #Get variables to build device string
        #-------------------------------------------------------
        #ID
        local ID
            if ([pick [/system/resource/get board-name] 0 3] != "CHR") do={
        set ID [/system/routerboard get serial-number];#ID
        } else={
            set ID [system/license/get system-id ]
        }

        local poststate do= {
            local state [serialize $data to=json]
            /iot/mqtt/publish broker="Home Assistant" message=$state topic="$discoverypath$domainpath$ID/$name/state" retain=yes
        }
        #-------------------------------------------------------
        #Handle routerboard firmware for non CHR
        #-------------------------------------------------------
        if ([pick [/system/resource/get board-name] 0 3] != "CHR") do={
            local data
            #Get routerboard firmware
            set ($data->"installed_version") [[parse "/system/routerboard/get current-firmware"]]
            set ($data->"latest_version") [[parse "/system/routerboard/get upgrade-firmware"]]
            #post Routerboard firmware
            $poststate name="RouterBOARD" data=$data ID=$ID discoverypath=$discoverypath domainpath=$domainpath
        }

        #-------------------------------------------------------
        #Handle RouterOS
        #-------------------------------------------------------
        #Get system software
        local versions [/system/package/update/check-for-updates as-value ]

        local data
        set ($data->"installed_version") ($versions->"installed-version")
        set ($data->"latest_version") ($versions->"latest-version")

        #Get release note:
        if (($HassioReleaseNote->"version")!=($data->"latest_version")) do={
            #:global HassioReleaseNote

            :set ($HassioReleaseNote->"note") ([/tool/fetch ("http://upgrade.mikrotik.com/routeros/".($data->"latest_version")."/CHANGELOG") output=user as-value]->"data")
            :set ($HassioReleaseNote->"note") [:pick ($HassioReleaseNote->"note") -1 255]
            :set ($HassioReleaseNote->"version") ($data->"latest_version")
            /log/debug message="HassioMQTT: Release note fetched."
        } else={/log/debug message="HassioMQTT: Release note already cached, not fetched."}
        set ($data->"release_summary") ($HassioReleaseNote->"note")

        local urls {development="https://mikrotik.com/download/changelogs/development-release-tree";\
            long-term="https://mikrotik.com/download/changelogs/long-term-release-tree";\
            stable="https://mikrotik.com/download/changelogs/stable-release-tree";\
            testing="https://mikrotik.com/download/changelogs/testing-release-tree"}
        set ($data->"release_url") ($urls->[system/package/update/get channel ])

        $poststate name="RouterOS" data=$data ID=$ID discoverypath=$discoverypath domainpath=$domainpath

        #-------------------------------------------------------
        #Handle LTE interfaces
        #-------------------------------------------------------
        :foreach iface in=[/interface/lte/ find] do={
        local ifacename [/interface/lte get $iface name]

        #Get manufacturer and model for LTE interface
        local lte [ [/interface/lte/monitor [/interface/lte get $iface name] once as-value] manufacturer]
            if ($lte->"manufacturer"="\"MikroTik\"") do={
                {
                local data
                #build config for LTE
                local modemname [:pick ($lte->"model")\
                    ([:find ($lte->"model") "\"" -1] +1)\
                    [:find ($lte->"model") "\"" [:find ($lte->"model") "\"" -1]]]

                #Get firmware version for LTE interface
                local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] as-value ]
                set ($data->"installed_version") ($Firmware->"installed")
                set ($data->"latest_version") ($Firmware->"latest")

                $poststate name=$modemname data=$data ID=$ID discoverypath=$discoverypath domainpath=$domainpath
                }
            }
        }
    }
}