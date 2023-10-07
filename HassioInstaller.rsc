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
    /system/script/add name=$fname policy=read source=$source
} else={
    #put [/system/script/get $index name]
    system/script/set $index policy=read,test source=$source
}

local fname "Hassio Firmware State Publish"
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20State%20Publish.rsc"
local source ([tool/fetch $url output=user as-value ]->"data")
local index [/system/script/find name=$fname]
if ( [len $index] =0) do={
    /system/script/add name=$fname policy=read source=$source
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
        /system/script/add name=$fname policy=read source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
    local fname "HassioSensorHealthStatePublish"
    local url ("https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/".$fname.".rsc")
    local source ([tool/fetch $url output=user as-value ]->"data")
    local index [/system/script/find name=$fname]
    if ( [len $index] =0) do={
        /system/script/add name=$fname policy=read source=$source
    } else={
        #put [/system/script/get $index name]
        system/script/set $index policy=read,test source=$source
    }
}
#Setup scheduler

put "Scheduler"
    
local fnames {"Hassio Firmware Entity Publish";"Hassio Firmware State Publish";"HassioSensorHealthEntityPublish";"HassioSensorHealthStatePublish"}





local fnames {"Hassio Firmware Entity Publish";"Hassio Firmware State Publish";"HassioSensorHealthEntityPublish";"HassioSensorHealthStatePublish"}
