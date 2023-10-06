#Install libs
local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioLib_DeviceString.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioLib_DeviceString" policy=read source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioLib_JsonEscape.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioLib_JsonEscape" policy=read source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioLib_JsonPick.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioLib_JsonPick" policy=read source=$source

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioLib_LowercaseHex.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioLib_LowercaseHex" policy=read source=$source 

local url "https://raw.githubusercontent.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry/main/HassioLib_SearchReplace.rsc"
global source ([tool/fetch $url output=user as-value ]->"data")
/system/script/add name="HassioLib_SearchReplace" policy=read source=$source

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


