#Install libs

local fnames {"HassioLib_DeviceString";"HassioLib_LowercaseHex";"HassioLib_SearchReplace"}


foreach fname in=$fnames do={
    #--------------------------------------------------------------
    put "installing: $fname"
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read source=$source
    }
    #--------------------------------------------------------------
}

#remove legacy libs if installed

local fnames {"HassioLib_JsonEscape";"HassioLib_JsonPick"}


foreach fname in=$fnames do={
    #--------------------------------------------------------------
    put "Removing: $fname"
    foreach func in=[/system/script/find name=$fname] do={
        /system/script/remove $func
    }
    #--------------------------------------------------------------
}


put "Functions"

    #--------------------------------------------------------------
local deploy do={
    put "installing: $fname"
    :if ([:len $url]=0) do={
        set $url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    }
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=$policy source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=$policy source=$source
    }
    system/script/run $fname
    local index [/system/scheduler/find name=$fname]
    if ( [len $index] =0) do={
        /system scheduler/add interval=$interval name=$fname on-event=$fname policy=\
        $policy start-date=2023-09-25 start-time=startup
    } else={
        #put [/system/script/get $index name]
        /system scheduler/set $index interval=$interval on-event=$fname policy=\
        $policy start-date=2023-09-25 start-time=startup
    }
}

local fname "HassioFirmwareEntityPublish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20Entity%20Publish.rsc"
local interval "0s"
local policy "read,test"

$deploy fname=$fname url=$url interval=$interval policy=$policy
 
   #--------------------------------------------------------------
local fname "HassioFirmwareStatePublish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20State%20Publish.rsc"
local interval "6h"
local policy "read,write,policy,test"

$deploy fname=$fname url=$url interval=$interval policy=$policy

if ([system/package/find name=gps and disabled=no]) do={
    put "GPS found, installing position telemetry..."
    #--------------------------------------------------------------
    local fname "HassioDeviceTrackerEntityPublish"
    local interval "0s"
    local policy "read,test"

    $deploy fname=$fname interval=$interval policy=$policy

    #--------------------------------------------------------------
    local fname "HassioDeviceTrackerStatePublish"
    local interval "1m"
    local policy "read,test"

    $deploy fname=$fname interval=$interval policy=$policy
}

if ([/system/package/find where name=ups and disabled=no]) do={
    if ([[:parse "len [/system/ups/find ]"]]>0) do={
        :put "UPS found"
        :local fname "HassioSensorUpsDevicePublish"
        :local interval "0s"
        :local policy "read,test"
        $deploy fname=$fname interval=$interval policy=$policy

        :local fname "HassioSensorUpsStatePublish"
        :local interval "1m"
        :local policy "read,test"
        $deploy fname=$fname interval=$interval policy=$policy
    }
}

if (!([/system/resource/get board-name ]~"^CHR")) do={
    if ([[:parse "[len [/system/health/find]]"]] >0) do={
        put "Health sensors found, installing telemetry..."    
        #--------------------------------------------------------------
        local fname "HassioSensorHealthEntityPublish"
        local interval "0s"
        local policy "read,test"

        $deploy fname=$fname interval=$interval policy=$policy
        #--------------------------------------------------------------
        local fname "HassioSensorHealthStatePublish"
        local interval "1m"
        local policy "read,write,test"

        $deploy fname=$fname interval=$interval policy=$policy
    }
    #--------------------------------------------------------------
    put "Checking for POE support..."
    :global PoeInstall false
    :execute "/interface/ethernet/poe/find; :set \$PoeInstall true"
    delay 1s
    if ($PoeInstall=true) do={
        put "   POE supported\n\r   Installing POE power monitor"
    #--------------------------------------------------------------
        local fname "HassioSensorPoeEntityPublish"
        local interval "0s"
        local policy "read,test"

        $deploy fname=$fname interval=$interval policy=$policy
    #--------------------------------------------------------------
        local fname "HassioSensorPoeStatePublish"
        local interval "1m"
        local policy "read,test"

        $deploy fname=$fname interval=$interval policy=$policy
    #--------------------------------------------------------------
    } else={
        put "   POE not supported"
    }
    set PoeInstall
}