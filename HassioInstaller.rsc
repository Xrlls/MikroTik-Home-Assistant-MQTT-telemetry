#Install libs

local fnames {"HassioLib_DeviceString";"HassioLib_JsonEscape";"HassioLib_JsonPick";"HassioLib_LowercaseHex";"HassioLib_SearchReplace"}


foreach fname in=$fnames do={
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
}

put "Functions"

local fname "Hassio Firmware Entity Publish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20Entity%20Publish.rsc"
local source ([tool/fetch $url output=user as-value ]->"data")
local index [/system/script/find name=$fname]
if ( [len $index] =0) do={
    /system/script/add name=$fname policy=read,write,policy,test source=$source
} else={
    #put [/system/script/get $index name]
    system/script/set $index policy=read,write,policy,test source=$source
}

local fname "Hassio Firmware State Publish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20State%20Publish.rsc"
local source ([tool/fetch $url output=user as-value ]->"data")
local index [/system/script/find name=$fname]
if ( [len $index] =0) do={
    /system/script/add name=$fname policy=read,write,policy,test source=$source
} else={
    #put [/system/script/get $index name]
    system/script/set $index policy=read,write,policy,test source=$source
}
if ([/system/resource/get board-name] != "CHR") do={    
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
    local fname "HassioSensorHealthStatePublish"
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read,test source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
}
#Setup scheduler

put "Scheduler"
    
local fnames {"Hassio Firmware Entity Publish";"Hassio Firmware State Publish";"HassioSensorHealthEntityPublish";"HassioSensorHealthStatePublish"}

local fname ($fnames->0)
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=0s on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
}

local fname ($fnames->1)
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=6h name=$fname on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=6h on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
}

local fname ($fnames->2)
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=0s name=$fname on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=0s on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
}

local fname ($fnames->3)
local index [/system/scheduler/find name=$fname]
if ( [len $index] =0) do={
    /system scheduler/add interval=1m name=$fname on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
} else={
    #put [/system/script/get $index name]
    /system scheduler/set $index interval=1m on-event=$fname policy=\
    read,write,test start-date=2023-09-25 start-time=startup
}
