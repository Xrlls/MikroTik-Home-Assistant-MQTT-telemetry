#Install libs

local fnames {"HassioLib_DeviceString";"HassioLib_JsonEscape";"HassioLib_JsonPick";"HassioLib_LowercaseHex";"HassioLib_SearchReplace"}


foreach fname in=$fnames do={
    #--------------------------------------------------------------
    put $fname
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    put $index

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
    put $fname
    foreach func in=[/system/script/find name=$fname] do={
        /system/script/remove $func
    }
    #--------------------------------------------------------------
}


put "Functions"

    #--------------------------------------------------------------
local fname "HassioFirmwareEntityPublish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20Entity%20Publish.rsc"
local source ([tool/fetch $url output=user as-value ]->"data")
local index [/system/script/find name=$fname]
if ( [len $index] =0) do={
    /system/script/add name=$fname policy=read,test source=$source
} else={
    #put [/system/script/get $index name]
    system/script/set $index policy=read,test source=$source
}
system/script/run $fname
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
    read,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=0s on-event=$fname policy=\
    read,test start-date=2023-09-25 start-time=startup
}
    #--------------------------------------------------------------
local fname "HassioFirmwareStatePublish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20State%20Publish.rsc"
local source ([tool/fetch $url output=user as-value ]->"data")
local index [/system/script/find name=$fname]
if ( [len $index] =0) do={
    /system/script/add name=$fname policy=read,write,policy,test source=$source
} else={
    #put [/system/script/get $index name]
    system/script/set $index policy=read,write,policy,test source=$source
}
system/script/run $fname
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=6h name=$fname on-event=$fname policy=\
    read,write,policy,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=6h on-event=$fname policy=\
    read,write,policy,test start-date=2023-09-25 start-time=startup
}

if ([system/package/find name=gps and disabled=no]) do={
    put "found"
    #--------------------------------------------------------------
    local fname "HassioDeviceTrackerEntityPublish"
    local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioDeviceTrackerEntityPublish.rsc"
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read,test source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
    system/script/run $fname
    local index [/system/scheduler/find name=$fname]
    if ( [len $index] =0) do={
        /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
        read,test start-time=startup
    } else={
        #put [/system/script/get $index name]
        /system scheduler/set $index interval=0s on-event=$fname policy=\
        read,test start-time=startup
    }
    #--------------------------------------------------------------
    local fname "HassioDeviceTrackerStatePublish"
    local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioDeviceTrackerStatePublish.rsc"
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read,test source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
    system/script/run $fname
    local index [/system/scheduler/find name=$fname]
    if ( [len $index] =0) do={
        /system scheduler/add interval=1m name=$fname on-event=$fname policy=\
        read,test start-time=startup
    } else={
        #put [/system/script/get $index name]
        /system scheduler/set $index interval=1m on-event=$fname policy=\
        read,test start-time=startup
    }
}



if ([/system/resource/get board-name] != "CHR") do={    
    #--------------------------------------------------------------
    local fname "HassioSensorHealthEntityPublish"
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read,test source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
    system/script/run $fname
    local index [/system/scheduler/find name=$fname]
    if ( [len $index] =0) do={
        /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
        read,write,test start-date=2023-09-25 start-time=startup
    } else={
        #put [/system/script/get $index name]
        /system scheduler/set $index interval=0s on-event=$fname policy=\
        read,write,test start-date=2023-09-25 start-time=startup
    }

    #--------------------------------------------------------------
    local fname "HassioSensorHealthStatePublish"
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read,write,test source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,write,test source=$source
    }
    system/script/run $fname
    local index [/system/scheduler/find name=$fname]
    if ( [len $index] =0) do={
        /system scheduler/add interval=1m name=$fname on-event=$fname policy=\
        read,write,test start-date=2023-09-25 start-time=startup
    } else={
        #put [/system/script/get $index name]
        /system scheduler/set $index interval=1m on-event=$fname policy=\
        read,write,test start-date=2023-09-25 start-time=startup
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
        local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
        local source ([tool/fetch $url output=user as-value ]->"data")
        local index [/system/script/find name=$fname]
        if ( [len $index] =0) do={
            /system/script/add name=$fname policy=read,test source=$source
        } else={
            #put [/system/script/get $index name]
            system/script/set $index policy=read,test source=$source
        }
        system/script/run $fname
        local index [/system/scheduler/find name=$fname]
        if ( [len $index] =0) do={
            /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
            read,write,test start-date=2023-09-25 start-time=startup
        } else={
            #put [/system/script/get $index name]
            /system scheduler/set $index interval=0s on-event=$fname policy=\
            read,write,test start-date=2023-09-25 start-time=startup
        }
    #--------------------------------------------------------------
        local fname "HassioSensorPoeStatePublish"
        local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
        local source ([tool/fetch $url output=user as-value ]->"data")
        local index [/system/script/find name=$fname]
        if ( [len $index] =0) do={
            /system/script/add name=$fname policy=read,test source=$source
        } else={
            #put [/system/script/get $index name]
            system/script/set $index policy=read,test source=$source
        }
        system/script/run $fname
        local index [/system/scheduler/find name=$fname]
        if ( [len $index] =0) do={
            /system scheduler/add interval=1m name=$fname on-event=$fname policy=\
            read,test start-date=2023-09-25 start-time=startup
        } else={
            #put [/system/script/get $index name]
            /system scheduler/set $index interval=1m on-event=$fname policy=\
            read,test start-date=2023-09-25 start-time=startup
        }
    #--------------------------------------------------------------
    } else={
        put "   POE not supported"
    }
    set PoeInstall
}
