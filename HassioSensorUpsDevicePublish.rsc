:local device
:local rdev [[parse [system/script/get "HassioLib_DeviceString" source]]]; #Get information from host router
foreach i in=[/system/ups/ find] do={
    #Defining device string
    :local delimiter "  FW:"
    :set ($device->"dev"->"mf") "APC"
    :set ($device->"dev"->"mdl") [/system/ups get $i model]
    :local delimiterIndex [find ($device->"dev"->"mdl") $delimiter]
    :if ([:len $delimiterIndex]>0) do={
        :set ($device->"dev"->"sw") [:pick ($device->"dev"->"mdl") ($delimiterIndex + [:len $delimiter]) [:len ($device->"dev"->"mdl")]]
        :set ($device->"dev"->"mdl") [:pick ($device->"dev"->"mdl") -1 $delimiterIndex]
        }
    :set ($device->"dev"->"sn") [/system/ups get $i serial]
    :set ($device ->"dev"->"ids") ($device->"dev"->"sn")
    :set ($device->"via_device") ($rdev->"dev"->"sn")
    :set ($device->"dev"->"name") [/system/ups get $i name]
    :set ($device->"dev"->"cu") ($rdev->"dev"->"cu")
    :set ($device->"o") ($rdev->"o")

    #Defining function to post data as Hassio auto discovery JSON to MQTT
    :local postdata do={
        :local discoverypath "homeassistant/"
        :local pd ($1,$2)
        :if ($3="sensor") do={:set ($pd->"exp_aft") 70}
        :set ($pd->"obj_id") (($2->"dev"->"sn")."_".($1->"obj_id"))
        :set ($pd->"uniq_id") ($pd->"obj_id")
        :set ($pd->"stat_t") ($discoverypath."sensor/".($2->"dev"->"sn")."/state")
        /iot/mqtt/publish broker="Home Assistant"\
            topic=($discoverypath.$3."/".($2->"dev"->"sn")."/".($1->"obj_id")."/config")\
            message=[:serialize $pd to=json]\
            retain=yes
    }

    :local sensorconfig
    :set ($sensorconfig->"name") "On-line"
    :set ($sensorconfig->"obj_id") "on_line"
    :set ($sensorconfig->"dev_cla") "power"
    :set ($sensorconfig->"val_tpl") ("{{ value_json.".($sensorconfig->"obj_id")." | is_defined }}")
    $postdata $sensorconfig $device "binary_sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Battery charge"
    :set ($sensorconfig->"obj_id") "battery_charge"
    :set ($sensorconfig->"sug_dsp_prc") 0
    :set ($sensorconfig->"unit_of_meas") "%"
    :set ($sensorconfig->"dev_cla") "battery"
    :set ($sensorconfig->"stat_cla") "measurement"
    :set ($sensorconfig->"val_tpl") ("{{ value_json.".($sensorconfig->"obj_id")." | is_defined }}")
    $postdata $sensorconfig $device "sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Load"
    :set ($sensorconfig->"obj_id") "load"
    :set ($sensorconfig->"sug_dsp_prc") 0
    :set ($sensorconfig->"unit_of_meas") "%"
    :set ($sensorconfig->"stat_cla") "measurement"
    :set ($sensorconfig->"val_tpl") ("{{ value_json.".($sensorconfig->"obj_id")." | is_defined }}")
    $postdata $sensorconfig $device "sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Runtime left"
    :set ($sensorconfig->"obj_id") "runtime_left"
    :set ($sensorconfig->"sug_dsp_prc") 2
    :set ($sensorconfig->"unit_of_meas") "min"
    :set ($sensorconfig->"dev_cla") "duration"
    :set ($sensorconfig->"stat_cla") "total"
    :set ($sensorconfig->"val_tpl") ("\
        {%if value_json.".($sensorconfig->"obj_id")." | is_defined%}\
            {{value_json.".($sensorconfig->"obj_id")."/60}}\
        {%endif%}")
    $postdata $sensorconfig $device "sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Battery voltage"
    :set ($sensorconfig->"obj_id") "battery_voltage"
    :set ($sensorconfig->"sug_dsp_prc") 1
    :set ($sensorconfig->"unit_of_meas") "V"
    :set ($sensorconfig->"dev_cla") "voltage"
    :set ($sensorconfig->"stat_cla") "measurement"
    :set ($sensorconfig->"val_tpl") ("\
        {%if value_json.".($sensorconfig->"obj_id")." | is_defined%}\
            {{value_json.".($sensorconfig->"obj_id")."/100}}\
        {%endif%}")
    $postdata $sensorconfig $device "sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Line voltage"
    :set ($sensorconfig->"obj_id") "line_voltage"
    :set ($sensorconfig->"sug_dsp_prc") 1
    :set ($sensorconfig->"unit_of_meas") "V"
    :set ($sensorconfig->"dev_cla") "voltage"
    :set ($sensorconfig->"stat_cla") "measurement"
    :set ($sensorconfig->"val_tpl") ("\
        {%if value_json.".($sensorconfig->"obj_id")." | is_defined%}\
            {{value_json.".($sensorconfig->"obj_id")."/100}}\
        {%endif%}")
    $postdata $sensorconfig $device "sensor"

    :set $sensorconfig
    :set ($sensorconfig->"name") "Self test"
    :set ($sensorconfig->"obj_id") "hid_self_test"
    :set ($sensorconfig->"dev_cla") "enum"
    :set ($sensorconfig->"val_tpl") ("{{ value_json.".($sensorconfig->"obj_id")." | is_defined }}")
    $postdata $sensorconfig $device "sensor"
}