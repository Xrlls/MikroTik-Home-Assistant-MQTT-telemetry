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
        system/script/set $index policy=read source=source=$source
    }
}

put "Functions"


#Install functions
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20Entity%20Publish.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="Hassio Firmware Entity Publish" policy=read,test source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/Hassio%20Firmware%20State%20Publish.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="Hassio Firmware State Publish" policy=read,write,policy,test source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioSensorHealthEntityPublish.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioSensorHealthEntityPublish" policy=read,test source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioSensorHealthStatePublish.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioSensorHealthStatePublish" policy=read,test source=$source

#Setup scheduler

