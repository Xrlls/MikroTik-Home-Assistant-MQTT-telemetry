{
    global discoverypath "homeassistant/"
    global domainpath "sensor/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------

    global ID
    if ([/system/resource/get board-name] != "CHR") do={
    set ID [/system/routerboard get serial-number];#ID
    } else={
    set ID [system/license/get system-id ]
    }
    #-------------------------------------------------------
    #Build device string
    #-------------------------------------------------------
    local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
    global dev [$DeviceString]
    global buildconfig do= {
        global discoverypath
        global domainpath
        global ID
        global dev

        #build config for Hassio
        local config "{\"name\":\"$name\",\
            \"stat_t\":\"$discoverypath$domainpath$ID/state\",\
            \"uniq_id\":\"$ID_$name\",\
            \"obj_id\":\"$ID_$name\",\
\"suggested_display_precision\": 1,\
      \"unit_of_measurement\": \"$unit\",\
      \"value_template\": \"{{ value_json.$name }}\",\
            $dev\
        }"
        /iot/mqtt/publish broker="Home Assistant" message=$config topic="$discoverypath$domainpath$ID/$name/config" retain=yes              
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        foreach sensor in=[/system/health/find] do={
        local name [/system/health/get $sensor name];#name
        local unit [/system/health/get $sensor type];#unit
        if ($unit="C") do={set $unit "\C2\B0\43"}
        $buildconfig name=$name unit=$unit
        }
    }
}