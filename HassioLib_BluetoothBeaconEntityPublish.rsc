#    :local PublishEntities do={

        :local postdata do={
            :local discoverypath "homeassistant/"
            :local dtopic [([:pick ($2->"dev"->"cns"->0->1) -1 2].[:pick ($2->"dev"->"cns"->0->1) 3 5].\
                            [:pick ($2->"dev"->"cns"->0->1) 6 8].[:pick ($2->"dev"->"cns"->0->1) 9 11].\
                            [:pick ($2->"dev"->"cns"->0->1) 12 14].[:pick ($2->"dev"->"cns"->0->1) 15 17])]
            :local pd ($1,$2)
            :if (($3="sensor") and !(($1->"dev_cla")="timestamp")) do={:set ($pd->"exp_aft") 70}
            :set ($pd->"~") ($discoverypath."sensor/".$dtopic."/state")
            :set ($pd->"avty_t") "~"
            :if ([:typeof ($1->"avty_tpl")]="nothing") do={
                :set ($pd->"avty_tpl") "{%if value_json.data is defined%}{{'online'}}{%else%}{{'offline'}}{%endif%}"
            }
            :set ($pd->"obj_id") ($dtopic."_".($1->"obj_id"))
            :set ($pd->"uniq_id") ($pd->"obj_id")
#            :set ($pd->"stat_t") ($discoverypath."sensor/".$dtopic."/state")
            :set ($pd->"stat_t") "~"
            /iot/mqtt/publish broker="Home Assistant"\
                topic=($discoverypath.$3."/".$dtopic."/".($1->"obj_id")."/config")\
                message=[:serialize $pd to=json]\
                retain=yes
        }

        #------------------------------------
        #Build device string
        #------------------------------------
        :local device
        :set ($device->"dev"->"cns"->0->0) "bluetooth"
        :set ($device->"dev"->"cns"->0->1) [:convert $1 transform=lc]
        :set ($device->"dev"->"ids") ($device->"dev"->"cns"->0->1)
        if ($2) do={:set ($device->"dev"->"mdl") "TG-BT5-OUT"} else={:set ($device->"dev"->"mdl") "TG-BT5-IN"}
        :set ($device->"dev"->"name") $1
        :set ($device->"dev"->"mf") "MikroTik"
        :set ($device->"o"->"name") "MikroTik-Home-Assistant-MQTT-telemetry"
        :set ($device->"o"->"url") "https://github.com/Xrlls/MikroTik-Home-Assistant-MQTT-telemetry"

        #------------------------------------
        #Create sensors
        #------------------------------------

        
        #Accelerometers
        {
        :local sensorconfig
        :set ($sensorconfig->"sug_dsp_prc") 2
        :set ($sensorconfig->"unit_of_meas") "m/s\C2\B2"
        :set ($sensorconfig->"exp_aft") 70
        #X
        :set ($sensorconfig->"name") "Acceleration X"
        :set ($sensorconfig->"obj_id") "acc_x"
        :set ($sensorconfig->"val_tpl") "{% set x= int(value_json.data[18:20] + value_json.data[16:18],base=16)%}{% if x>0x7fff%}{% set x=x-0x10000%}{%endif%}{{x*9.82/256}}"
        :set ($sensorconfig->"ic") "mdi:axis-x-arrow"
        $postdata $sensorconfig $device "sensor"
        #Y
        :set ($sensorconfig->"name") "Acceleration Y"
        :set ($sensorconfig->"obj_id") "acc_y"
        :set ($sensorconfig->"val_tpl") "{% set y= int(value_json.data[22:24] + value_json.data[20:22],base=16)%}{% if y>0x7fff%}{% set y=y-0x10000%}{%endif%}{{y*9.82/256}}"
        :set ($sensorconfig->"ic") "mdi:axis-y-arrow"
        $postdata $sensorconfig $device "sensor"
        #Z
        :set ($sensorconfig->"name") "Acceleration Z"
        :set ($sensorconfig->"obj_id") "acc_z"
        :set ($sensorconfig->"val_tpl") "{% set z= int(value_json.data[26:28] + value_json.data[24:26],base=16)%}{% if z>0x7fff%}{% set z=z-0x10000%}{%endif%}{{z*9.82/256}}"
        :set ($sensorconfig->"ic") "mdi:axis-z-arrow"
        $postdata $sensorconfig $device "sensor"
        }
        #Thermometer
        if ($2) do=\
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Temperature"
        :set ($sensorconfig->"obj_id") "temp"                                                               
        :set ($sensorconfig->"sug_dsp_prc") 1
        :set ($sensorconfig->"unit_of_meas") "\C2\B0\43"
        :set ($sensorconfig->"exp_aft") 70
        :set ($sensorconfig->"dev_cla") "temperature"
        :set ($sensorconfig->"val_tpl") "{% set t= int(value_json.data[30:32] + value_json.data[28:30],base=16)%}{% if t>0x7fff%}{% set t=t-0x10000%}{%endif%}{{t/256}}"
        $postdata $sensorconfig $device "sensor"
        }
        #Uptime
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Uptime"
        :set ($sensorconfig->"obj_id") "uptime"                                                               
        :set ($sensorconfig->"sug_dsp_prc") 1
        :set ($sensorconfig->"unit_of_meas") "min"
        :set ($sensorconfig->"exp_aft") 70
        :set ($sensorconfig->"dev_cla") "duration"
        :set ($sensorconfig->"ent_cat") "diagnostic"
        :set ($sensorconfig->"val_tpl") "{{ int(value_json.data[38:40] + value_json.data[36:38] + value_json.data[34:36] + value_json.data[32:34],base=16)/60}}"
        $postdata $sensorconfig $device "sensor"
        }
        #RSSI
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "RSSI"
        :set ($sensorconfig->"obj_id") "rssi"                                                               
        :set ($sensorconfig->"sug_dsp_prc") 0
        :set ($sensorconfig->"unit_of_meas") "dB"
        :set ($sensorconfig->"exp_aft") 70
        :set ($sensorconfig->"dev_cla") "signal_strength"
        :set ($sensorconfig->"ent_cat") "diagnostic"
        :set ($sensorconfig->"val_tpl") ("{{ value_json.rssi | is_defined }}")
        :set ($sensorconfig->"avty_tpl") "{%if value_json.rssi is defined%}{{'online'}}{%else%}{{'offline'}}{%endif%}"
        $postdata $sensorconfig $device "sensor"
        }
        #Timestamp
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Last seen"
        :set ($sensorconfig->"obj_id") "last_seen"                                                               
        :set ($sensorconfig->"dev_cla") "timestamp"
        :set ($sensorconfig->"ent_cat") "diagnostic"
        :set ($sensorconfig->"val_tpl") ("{{ value_json.last_seen | is_defined }}")
        :set ($sensorconfig->"avty_tpl") "{%if value_json.last_seen is defined%}{{'online'}}{%else%}{{'offline'}}{%endif%}"
        $postdata $sensorconfig $device "sensor"
        }
        #Battery
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Battery"
        :set ($sensorconfig->"obj_id") "battery"
        :set ($sensorconfig->"sug_dsp_prc") 0
        :set ($sensorconfig->"unit_of_meas") "%"
        :set ($sensorconfig->"exp_aft") 70
        :set ($sensorconfig->"dev_cla") "battery"
        :set ($sensorconfig->"val_tpl") "{{int(value_json.data[42:44],base=16) }}"
        $postdata $sensorconfig $device "sensor"
        }
        #Binary sensors
        #X
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Impact X"
        :set ($sensorconfig->"obj_id") "imp_x"
        :set ($sensorconfig->"en") false
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[41:42],base=16) | bitwise_and(0x08))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:axis-x-arrow"
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Y
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Impact Y"
        :set ($sensorconfig->"obj_id") "imp_y"
        :set ($sensorconfig->"en") false
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[40:41],base=16) | bitwise_and(0x01))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:axis-y-arrow"
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Z
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Impact Z"
        :set ($sensorconfig->"obj_id") "imp_z"
        :set ($sensorconfig->"en") false
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[40:41],base=16) | bitwise_and(0x02))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:axis-z-arrow"
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Free fall
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Free fall"
        :set ($sensorconfig->"obj_id") "freefall"
        :set ($sensorconfig->"en") false
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[41:42],base=16) | bitwise_and(0x04))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:arrow-down-bold-box-outline"
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Tilt
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Tilt"
        :set ($sensorconfig->"obj_id") "Tilt"
        :set ($sensorconfig->"en") false
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[41:42],base=16) | bitwise_and(0x02))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:spirit-level"
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Switch
        {
        :local sensorconfig
        :set ($sensorconfig->"name") "Switch"
        :set ($sensorconfig->"obj_id") "Switch"
        :set ($sensorconfig->"val_tpl") "{% if((int(value_json.data[41:42],base=16) | bitwise_and(0x01))|bool)%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}"
        :set ($sensorconfig->"ic") "mdi:magnet-on"
        
        $postdata $sensorconfig $device "binary_sensor"
        }
        #Devicetracker
        {
        :local sensorconfig $device
        :set ($sensorconfig->"name") "Location"
        :set ($sensorconfig->"obj_id") "loc"
        :local discoverypath "homeassistant/"
        :local dtopic [([:pick ($device->"dev"->"cns"->0->1) -1 2].[:pick ($device->"dev"->"cns"->0->1) 3 5].\
                        [:pick ($device->"dev"->"cns"->0->1) 6 8].[:pick ($device->"dev"->"cns"->0->1) 9 11].\
                        [:pick ($device->"dev"->"cns"->0->1) 12 14].[:pick ($device->"dev"->"cns"->0->1) 15 17])]
        :set ($sensorconfig->"obj_id") ($dtopic."_".($sensorconfig->"obj_id"))
        :set ($sensorconfig->"uniq_id") ($sensorconfig->"obj_id")
        :set ($sensorconfig->"~") $discoverypath
        :set ($sensorconfig->"stat_t") ("~device_tracker/".$dtopic."/state")
        :set ($sensorconfig->"pl_rst") "hassio_gps_derive"
        :set ($sensorconfig->"src_type") "bluetooth"
        :set ($sensorconfig->"json_attr_t") ("~sensor/".$dtopic."/state")
        /iot/mqtt/publish broker="Home Assistant"\
            topic=($discoverypath."device_tracker/".$dtopic."/config")\
            message=[:serialize $sensorconfig to=json] retain=yes
        }
#    }
