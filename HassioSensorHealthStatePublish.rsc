{
    global discoverypath "homeassistant/"
    global domainpath "sensor/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    global ID [/system/routerboard get serial-number] 

    if ([/system/resource/get board-name] != "CHR") do={
        local string "{"
        foreach sensor in=[/system/health/find] do={
            set $string (($string).("\"").\
                ([/system/health/get $sensor name]).("\":").\
                ([/system/health/get $sensor value]).(","))
        }
    set $string ([pick $string -1 ([len $string ]-1)]."}")
    
    /iot/mqtt/publish broker="Home Assistant" message=$string topic="$discoverypath$domainpath$ID/state" retain=yes   
    }
}